//+------------------------------------------------------------------+
//|                                     CrossSectionalMomentum.mq5   |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                                        https://www.berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Quantitative Research"
#property link      "https://www.berrytrade.org"
#property version   "1.00"
#property description "Cross-Sectional Currency Basket Momentum Strategy"
#property description "Academic Relative Strength Sorting across G10 Currencies with Volatility Parity and Hard Stop-Loss"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "=== Risk Management & Sizing ==="
input double   InpRiskPercent          = 1.0;       // Risk percentage per trade (e.g. 1.0%)
input double   InpFixedLotSize         = 0.0;       // Fixed lot size (0 = use Dynamic Risk Sizing)
input int      InpSlippagePoints       = 10;        // Max slippage points
input ulong    InpMagicNumber          = 109001;    // EA Magic Number

input group "=== Cross-Sectional Momentum Engine ==="
input int      InpLookbackBars         = 48;        // Momentum lookback horizon (bars, e.g. 48 H4 bars = 8 days)
input string   InpBasketSymbols        = "EURUSD,GBPUSD,AUDUSD,USDJPY"; // Currency universe
input double   InpMomentumThreshold    = 0.015;     // Minimum standardized momentum differential (1.5%)
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

   Print("[+] CrossSectionalMomentum initialized successfully for ", _Symbol, " on timeframe ", EnumToString(_Period));
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
   Print("[-] CrossSectionalMomentum deinitialized. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//| Compute Relative Strength Momentum across Cross-Section Basket   |
//+------------------------------------------------------------------+
bool CalculateBasketMomentum(double &symbolScore, double &basketMedianScore)
{
   string symbols[];
   int totalSymbols = StringSplit(InpBasketSymbols, ',', symbols);
   if(totalSymbols <= 0)
      return false;

   double scores[];
   ArrayResize(scores, totalSymbols);

   int currentSymbolIdx = -1;

   for(int i = 0; i < totalSymbols; i++)
   {
      StringTrimLeft(symbols[i]);
      StringTrimRight(symbols[i]);

      if(symbols[i] == _Symbol)
         currentSymbolIdx = i;

      double closeCurrent = iClose(symbols[i], _Period, 1);
      double closePrior   = iClose(symbols[i], _Period, InpLookbackBars);

      if(closeCurrent > 0.0 && closePrior > 0.0)
      {
         // Logarithmic return
         double logReturn = MathLog(closeCurrent / closePrior);
         
         // Volatility standardization using local ATR
         int tempATR = iATR(symbols[i], _Period, InpATRPeriod);
         double atrVal[];
         ArraySetAsSeries(atrVal, true);
         double vol = 0.01;
         if(tempATR != INVALID_HANDLE && CopyBuffer(tempATR, 0, 1, 1, atrVal) > 0)
         {
            vol = atrVal[0] / closeCurrent;
            IndicatorRelease(tempATR);
         }
         if(vol > 0.0)
            scores[i] = logReturn / vol;
         else
            scores[i] = logReturn;
      }
      else
      {
         scores[i] = 0.0;
      }
   }

   if(currentSymbolIdx < 0)
   {
      symbolScore = 0.0;
      basketMedianScore = 0.0;
      return false;
   }

   symbolScore = scores[currentSymbolIdx];

   // Calculate median basket score
   ArraySort(scores);
   int mid = totalSymbols / 2;
   if(totalSymbols % 2 == 1)
      basketMedianScore = scores[mid];
   else
      basketMedianScore = 0.5 * (scores[mid - 1] + scores[mid]);

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

   double symbolScore = 0.0;
   double basketMedianScore = 0.0;

   if(!CalculateBasketMomentum(symbolScore, basketMedianScore))
      return;

   long existingPosType = -1;
   bool hasPosition = HasOpenPosition(existingPosType);

   double relativeDiff = symbolScore - basketMedianScore;

   // Trading Signals:
   // Strong Outperformer (top quartile vs basket) -> Long
   bool buySignal = (relativeDiff > InpMomentumThreshold);
   // Strong Underperformer (bottom quartile vs basket) -> Short
   bool sellSignal = (relativeDiff < -InpMomentumThreshold);

   int digits = (int)ExtSymbol.Digits();
   double ask = ExtSymbol.Ask();
   double bid = ExtSymbol.Bid();

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
            if(ExtTrade.Buy(lots, _Symbol, ask, stopLossPrice, takeProfitPrice, "CrossSectional Momentum Buy"))
            {
               Print("[+] BUY Executed: Lots=", lots, " Entry=", ask, " SL=", stopLossPrice, " TP=", takeProfitPrice, " ScoreDiff=", relativeDiff);
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
            if(ExtTrade.Sell(lots, _Symbol, bid, stopLossPrice, takeProfitPrice, "CrossSectional Momentum Sell"))
            {
               Print("[+] SELL Executed: Lots=", lots, " Entry=", bid, " SL=", stopLossPrice, " TP=", takeProfitPrice, " ScoreDiff=", relativeDiff);
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
      // Defensive exit on momentum exhaustion / rank inversion
      if(existingPosType == POSITION_TYPE_BUY && relativeDiff < -InpMomentumThreshold * 0.5)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Closed Long position on momentum degradation.");
            }
         }
      }
      else if(existingPosType == POSITION_TYPE_SELL && relativeDiff > InpMomentumThreshold * 0.5)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Closed Short position on momentum degradation.");
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
