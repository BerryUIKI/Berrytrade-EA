//+------------------------------------------------------------------+
//|                                             VolBreakoutATR.mq5   |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                                        https://www.berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Quantitative Research"
#property link      "https://www.berrytrade.org"
#property version   "1.00"
#property description "VolBreakoutATR: Parkinson & Garman-Klass Volatility Breakout System"
#property description "Exploits extreme-value volatility contraction-expansion cycles with dynamic fractional risk."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters: Risk Management & Execution
input group "=== Risk Management & Position Sizing ==="
input double   InpRiskPercent          = 1.0;       // Risk percentage per trade (e.g. 1.0%)
input double   InpFixedLotSize         = 0.0;       // Fixed lot size (0 = use Dynamic Risk Sizing)
input int      InpSlippagePoints       = 10;        // Max slippage points
input ulong    InpMagicNumber          = 108001;    // EA Magic Number

input group "=== Volatility Estimator & Breakout Parameters ==="
input int      InpLookbackBars         = 20;        // Volatility estimation window (bars)
input double   InpSqueezeThreshold     = 0.75;      // Squeeze compression threshold ratio
input double   InpExpansionThreshold   = 1.10;      // Volatility expansion trigger ratio
input int      InpBreakoutChannelBars  = 20;        // Donchian breakout envelope lookback
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

   Print("[+] VolBreakoutATR initialized successfully for ", _Symbol, " on timeframe ", EnumToString(_Period));
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
   Print("[-] VolBreakoutATR deinitialized. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//| Calculate Garman-Klass Extreme-Value Volatility & Breakout Bounds|
//+------------------------------------------------------------------+
bool CalculateVolatilityAndBounds(double &gkVol, double &upperBound, double &lowerBound, bool &wasSqueezed)
{
   int totalRequired = MathMax(InpLookbackBars, InpBreakoutChannelBars) + 5;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(_Symbol, _Period, 1, totalRequired, rates);
   if(copied < totalRequired)
      return false;

   // 1. Calculate Garman-Klass (1980) extreme-value variance estimator
   // sigma^2 = (1/N) * sum [ 0.5 * (ln(H/L))^2 - (2*ln(2) - 1) * (ln(C/O))^2 ]
   double sumGK = 0.0;
   double c1 = 0.5;
   double c2 = 2.0 * MathLog(2.0) - 1.0;

   for(int i = 0; i < InpLookbackBars; i++)
   {
      if(rates[i].low <= 0.0 || rates[i].open <= 0.0)
         continue;

      double u = MathLog(rates[i].high / rates[i].low);
      double c = MathLog(rates[i].close / rates[i].open);

      sumGK += (c1 * u * u - c2 * c * c);
   }

   double varGK = sumGK / InpLookbackBars;
   if(varGK > 0.0)
      gkVol = MathSqrt(varGK);
   else
      gkVol = 0.0;

   // 2. Compute Donchian envelope boundaries across completed bars
   upperBound = rates[0].high;
   lowerBound = rates[0].low;

   for(int i = 1; i < InpBreakoutChannelBars; i++)
   {
      if(rates[i].high > upperBound)
         upperBound = rates[i].high;
      if(rates[i].low < lowerBound)
         lowerBound = rates[i].low;
   }

   // 3. Test if prior bars underwent volatility compression (squeeze)
   // by comparing historical GK vol across window
   double historicalSum = 0.0;
   for(int i = 5; i < InpLookbackBars + 5; i++)
   {
      if(rates[i].low <= 0.0 || rates[i].open <= 0.0)
         continue;
      double u = MathLog(rates[i].high / rates[i].low);
      double c = MathLog(rates[i].close / rates[i].open);
      historicalSum += (c1 * u * u - c2 * c * c);
   }
   double priorGKVol = MathSqrt(MathMax(0.0, historicalSum / InpLookbackBars));

   wasSqueezed = (priorGKVol > 0.0 && (gkVol / priorGKVol) <= InpSqueezeThreshold);

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

   // 3. New bar filtration: Execute entries strictly at bar open to prevent whipsaws
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == ExtLastBarTime)
      return;

   double gkVol = 0.0;
   double upperBound = 0.0;
   double lowerBound = 0.0;
   bool wasSqueezed = false;

   if(!CalculateVolatilityAndBounds(gkVol, upperBound, lowerBound, wasSqueezed))
      return;

   long existingPosType = -1;
   bool hasPosition = HasOpenPosition(existingPosType);

   double closePrev = iClose(_Symbol, _Period, 1);
   int digits = (int)ExtSymbol.Digits();
   double ask = ExtSymbol.Ask();
   double bid = ExtSymbol.Bid();

   // Trading Signals:
   // Breakout Above Channel with Volatility Expansion
   bool buySignal = (closePrev > upperBound);
   // Breakout Below Channel with Volatility Expansion
   bool sellSignal = (closePrev < lowerBound);

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
            if(ExtTrade.Buy(lots, _Symbol, ask, stopLossPrice, takeProfitPrice, "VolBreakoutATR Buy"))
            {
               Print("[+] BUY Executed: Lots=", lots, " Entry=", ask, " SL=", stopLossPrice, " TP=", takeProfitPrice, " GKVol=", gkVol);
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
            if(ExtTrade.Sell(lots, _Symbol, bid, stopLossPrice, takeProfitPrice, "VolBreakoutATR Sell"))
            {
               Print("[+] SELL Executed: Lots=", lots, " Entry=", bid, " SL=", stopLossPrice, " TP=", takeProfitPrice, " GKVol=", gkVol);
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
      // Defensive exit on counter-trend reversal penetration
      if(existingPosType == POSITION_TYPE_BUY && closePrev < lowerBound)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Closed Long position on counter-trend breakout penetration.");
            }
         }
      }
      else if(existingPosType == POSITION_TYPE_SELL && closePrev > upperBound)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Closed Short position on counter-trend breakout penetration.");
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
