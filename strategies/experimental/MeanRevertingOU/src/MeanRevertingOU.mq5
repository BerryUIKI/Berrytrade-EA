//+------------------------------------------------------------------+
//|                                             MeanRevertingOU.mq5  |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                                        https://www.berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Quantitative Research"
#property link      "https://www.berrytrade.org"
#property version   "1.00"
#property description "MeanRevertingOU: Continuous Ornstein-Uhlenbeck Analytical Half-Life Reversion"
#property description "Models mean-reverting drift theta(mu - X_t)dt with dynamic AR(1) estimation, half-life validation, and hard SL."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters: Risk Management & Execution
input group "=== Risk Management & Position Sizing ==="
input double   InpRiskPercent          = 1.0;       // Risk percentage per trade (e.g. 1.0%)
input double   InpFixedLotSize         = 0.0;       // Fixed lot size (0 = use Dynamic Risk Sizing)
input int      InpSlippagePoints       = 10;        // Max slippage points
input ulong    InpMagicNumber          = 110001;    // EA Magic Number

input group "=== Ornstein-Uhlenbeck Engine Parameters ==="
input int      InpEstimationBars       = 60;        // Rolling AR(1) estimation window (bars)
input double   InpEntryZScore          = 2.0;       // Entry threshold (standard deviations from mu)
input double   InpExitZScore           = 0.25;      // Exit threshold (standard deviations from mu)
input double   InpMinHalfLifeBars      = 2.0;       // Minimum admissible half-life (bars)
input double   InpMaxHalfLifeBars      = 30.0;      // Maximum admissible half-life (bars)
input int      InpATRPeriod            = 14;        // ATR volatility period for SL/TP
input double   InpStopLossATRMult      = 2.0;       // Hard Stop Loss multiplier (x ATR)
input double   InpTakeProfitATRMult    = 3.5;       // Take Profit multiplier (x ATR)
input bool     InpUseTrailingStop      = true;      // Enable ATR Trailing Stop
input double   InpTrailingATRMult      = 1.5;       // Trailing Stop trigger/step (x ATR)

//--- Global Variables & Objects
CTrade         ExtTrade;
CPositionInfo  ExtPosition;
CSymbolInfo    ExtSymbol;

int            ExtATRHandle            = INVALID_HANDLE;
datetime       ExtLastBarTime          = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!ExtSymbol.Name(_Symbol))
   {
      Print("[!] Error: Failed to initialize CSymbolInfo for symbol: ", _Symbol);
      return INIT_FAILED;
   }
   ExtSymbol.Refresh();

   ExtTrade.SetExpertMagicNumber(InpMagicNumber);
   ExtTrade.SetDeviationInPoints(InpSlippagePoints);
   ExtTrade.SetTypeFillingBySymbol(_Symbol);

   // Initialize ATR Indicator Handle
   ExtATRHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(ExtATRHandle == INVALID_HANDLE)
   {
      Print("[!] Error: Failed to create ATR indicator handle.");
      return INIT_FAILED;
   }

   Print("[+] MeanRevertingOU initialized successfully for ", _Symbol, " on timeframe ", EnumToString(_Period));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(ExtATRHandle != INVALID_HANDLE)
   {
      IndicatorRelease(ExtATRHandle);
      ExtATRHandle = INVALID_HANDLE;
   }
   Print("[-] MeanRevertingOU deinitialized. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//| Estimate Ornstein-Uhlenbeck Parameters & Normalized Z-Score      |
//+------------------------------------------------------------------+
bool EstimateOUParameters(double &zScore, double &halfLife, double &mu, double &theta)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(_Symbol, _Period, 1, InpEstimationBars + 1, rates);
   if(copied < InpEstimationBars + 1)
      return false;

   // Discrete AR(1) representation: X_k = a + b * X_{k-1} + e_k
   // where b = exp(-theta * dt), a = mu * (1 - exp(-theta * dt))
   int N = InpEstimationBars;
   double sumX = 0.0;
   double sumY = 0.0;
   double sumXX = 0.0;
   double sumXY = 0.0;

   for(int i = 0; i < N; i++)
   {
      double x = rates[i + 1].close; // X_{k-1}
      double y = rates[i].close;     // X_k

      sumX += x;
      sumY += y;
      sumXX += x * x;
      sumXY += x * y;
   }

   double denom = (N * sumXX - sumX * sumX);
   if(MathAbs(denom) < 1e-12)
      return false;

   double b = (N * sumXY - sumX * sumY) / denom;
   double a = (sumY - b * sumX) / N;

   // Check mean-reversion stability: 0 < b < 1
   if(b <= 0.001 || b >= 0.999)
      return false;

   // Continuous OU parameters (assuming dt = 1.0 bar interval)
   theta = -MathLog(b);
   mu = a / (1.0 - b);
   halfLife = MathLog(2.0) / theta;

   // Validate half-life bounds
   if(halfLife < InpMinHalfLifeBars || halfLife > InpMaxHalfLifeBars)
      return false;

   // Residual variance
   double sse = 0.0;
   for(int i = 0; i < N; i++)
   {
      double x = rates[i + 1].close;
      double y = rates[i].close;
      double pred = a + b * x;
      double res = y - pred;
      sse += res * res;
   }
   double varRes = sse / (N - 2);

   // Equilibrium standard deviation: sigma_eq = sqrt(varRes / (1 - b^2))
   double denomVar = 1.0 - b * b;
   if(denomVar <= 0.0 || varRes <= 0.0)
      return false;

   double sigmaEq = MathSqrt(varRes / denomVar);
   if(sigmaEq <= 0.0)
      return false;

   double latestPrice = rates[0].close;
   zScore = (latestPrice - mu) / sigmaEq;

   return true;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Fractional Risk Lot Size                       |
//+------------------------------------------------------------------+
double CalculateDynamicLotSize(double stopLossDistancePrice)
{
   if(InpFixedLotSize > 0.0)
      return InpFixedLotSize;

   if(!ExtSymbol.Refresh())
      return ExtSymbol.LotsMin();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * (InpRiskPercent / 100.0);

   double tickSize = ExtSymbol.TickSize();
   double tickValue = ExtSymbol.TickValue();

   if(tickSize <= 0.0 || tickValue <= 0.0 || stopLossDistancePrice <= 0.0)
      return ExtSymbol.LotsMin();

   double stopLossTicks = stopLossDistancePrice / tickSize;
   double moneyPerLot = stopLossTicks * tickValue;

   if(moneyPerLot <= 0.0)
      return ExtSymbol.LotsMin();

   double lotSize = riskMoney / moneyPerLot;

   // Constrain to broker volume specifications
   double lotStep = ExtSymbol.LotsStep();
   double minLot  = ExtSymbol.LotsMin();
   double maxLot  = ExtSymbol.LotsMax();

   lotSize = MathFloor(lotSize / lotStep) * lotStep;

   if(lotSize < minLot)
      lotSize = minLot;
   if(lotSize > maxLot)
      lotSize = maxLot;

   return lotSize;
}

//+------------------------------------------------------------------+
//| Check Existing Positions                                         |
//+------------------------------------------------------------------+
bool HasOpenPosition(long &existingType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPosition.SelectByIndex(i))
      {
         if(ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
         {
            existingType = ExtPosition.PositionType();
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Trailing Stop Management                                         |
//+------------------------------------------------------------------+
void ManageTrailingStop(double currentATR)
{
   if(!InpUseTrailingStop || currentATR <= 0.0)
      return;

   double trailDistance = currentATR * InpTrailingATRMult;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPosition.SelectByIndex(i))
      {
         if(ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
         {
            double openPrice = ExtPosition.PriceOpen();
            double currentSL = ExtPosition.StopLoss();
            double currentTP = ExtPosition.TakeProfit();
            ulong ticket = ExtPosition.Ticket();

            if(ExtPosition.PositionType() == POSITION_TYPE_BUY)
            {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               if(bid - openPrice > trailDistance)
               {
                  double newSL = bid - trailDistance;
                  if(newSL > currentSL + _Point * 5)
                  {
                     ExtTrade.PositionModify(ticket, NormalizeDouble(newSL, (int)ExtSymbol.Digits()), currentTP);
                  }
               }
            }
            else if(ExtPosition.PositionType() == POSITION_TYPE_SELL)
            {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               if(openPrice - ask > trailDistance)
               {
                  double newSL = ask + trailDistance;
                  if(currentSL == 0.0 || newSL < currentSL - _Point * 5)
                  {
                     ExtTrade.PositionModify(ticket, NormalizeDouble(newSL, (int)ExtSymbol.Digits()), currentTP);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Synchronize symbol quotes
   if(!ExtSymbol.RefreshRates())
      return;

   // 1. Fetch real-time ATR
   double atrValues[];
   ArraySetAsSeries(atrValues, true);
   if(CopyBuffer(ExtATRHandle, 0, 0, 3, atrValues) < 3)
      return;
   double currentATR = atrValues[0];

   // 2. Continuous Trailing Stop Audit
   ManageTrailingStop(currentATR);

   // 3. New bar filtration: Execute entries strictly at bar open
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == ExtLastBarTime)
      return;

   double zScore = 0.0;
   double halfLife = 0.0;
   double mu = 0.0;
   double theta = 0.0;

   if(!EstimateOUParameters(zScore, halfLife, mu, theta))
      return;

   long existingPosType = -1;
   bool hasPosition = HasOpenPosition(existingPosType);

   int digits = (int)ExtSymbol.Digits();
   double ask = ExtSymbol.Ask();
   double bid = ExtSymbol.Bid();

   // Trading Signals:
   // Oversold relative to equilibrium -> Long
   bool buySignal = (zScore <= -InpEntryZScore);
   // Overbought relative to equilibrium -> Short
   bool sellSignal = (zScore >= InpEntryZScore);

   if(!hasPosition)
   {
      if(buySignal && !sellSignal)
      {
         double slDistance = currentATR * InpStopLossATRMult;
         double tpDistance = currentATR * InpTakeProfitATRMult;
         double stopLossPrice = NormalizeDouble(ask - slDistance, digits);
         double takeProfitPrice = (InpTakeProfitATRMult > 0.0) ? NormalizeDouble(ask + tpDistance, digits) : 0.0;
         double lots = CalculateDynamicLotSize(slDistance);

         if(lots > 0.0)
         {
            if(ExtTrade.Buy(lots, _Symbol, ask, stopLossPrice, takeProfitPrice, "MeanRevertingOU Buy"))
            {
               Print("[+] BUY Executed: Lots=", lots, " Entry=", ask, " SL=", stopLossPrice, " TP=", takeProfitPrice, " Z=", zScore, " HalfLife=", halfLife);
               ExtLastBarTime = currentBarTime;
            }
            else
            {
               Print("[!] BUY Execution Failed: ", ExtTrade.ResultRetcode(), " - ", ExtTrade.ResultRetcodeDescription());
            }
         }
      }
      else if(sellSignal && !buySignal)
      {
         double slDistance = currentATR * InpStopLossATRMult;
         double tpDistance = currentATR * InpTakeProfitATRMult;
         double stopLossPrice = NormalizeDouble(bid + slDistance, digits);
         double takeProfitPrice = (InpTakeProfitATRMult > 0.0) ? NormalizeDouble(bid - tpDistance, digits) : 0.0;
         double lots = CalculateDynamicLotSize(slDistance);

         if(lots > 0.0)
         {
            if(ExtTrade.Sell(lots, _Symbol, bid, stopLossPrice, takeProfitPrice, "MeanRevertingOU Sell"))
            {
               Print("[+] SELL Executed: Lots=", lots, " Entry=", bid, " SL=", stopLossPrice, " TP=", takeProfitPrice, " Z=", zScore, " HalfLife=", halfLife);
               ExtLastBarTime = currentBarTime;
            }
            else
            {
               Print("[!] SELL Execution Failed: ", ExtTrade.ResultRetcode(), " - ", ExtTrade.ResultRetcodeDescription());
            }
         }
      }
   }
   else
   {
      // Mean reversion completion: Liquidate when price returns to equilibrium (|Z| <= InpExitZScore)
      if(existingPosType == POSITION_TYPE_BUY && zScore >= -InpExitZScore)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Mean Reversion Completed: Closed Long position at Z=", zScore);
            }
         }
      }
      else if(existingPosType == POSITION_TYPE_SELL && zScore <= InpExitZScore)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Mean Reversion Completed: Closed Short position at Z=", zScore);
            }
         }
      }
      // Structural Divergence Stop: Invalidate position if Z blows out beyond 3.5 sigma
      else if((existingPosType == POSITION_TYPE_BUY && zScore < -3.5) ||
              (existingPosType == POSITION_TYPE_SELL && zScore > 3.5))
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[!] Structural Divergence: Closed position on extreme Z breakout: ", zScore);
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
