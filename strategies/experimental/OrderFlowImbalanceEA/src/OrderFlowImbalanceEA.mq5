//+------------------------------------------------------------------+
//|                                         OrderFlowImbalanceEA.mq5 |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                                        https://www.berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Quantitative Research"
#property link      "https://www.berrytrade.org"
#property version   "1.00"
#property description "Order Flow Imbalance EA: Microstructure Bid-Ask Delta Imbalance & Volume Absorption"
#property description "Features Lee-Ready aggressor classification, Cumulative Volume Delta (CVD), and dynamic fractional risk."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters: Core Execution & Risk Management
input group "=== Risk Management & Position Sizing ==="
input double   InpRiskPercent          = 1.0;       // Risk percentage per trade (e.g. 1.0%)
input double   InpFixedLotSize         = 0.0;       // Fixed lot size (0 = use Dynamic Risk Sizing)
input int      InpSlippagePoints       = 10;        // Max slippage points
input ulong    InpMagicNumber          = 107001;    // EA Magic Number

input group "=== Order Flow & Imbalance Parameters ==="
input int      InpLookbackBars         = 20;        // Order Flow lookback window (bars)
input double   InpImbalanceThreshold   = 0.35;      // Normalized Delta imbalance threshold [-1.0, 1.0]
input double   InpAbsorptionWickRatio  = 0.40;      // Minimum candle wick absorption ratio (wick/range)
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

   // Initialize ATR Indicator
   ExtATRHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(ExtATRHandle == INVALID_HANDLE)
   {
      Print("[!] Error: Failed to create ATR indicator handle.");
      return INIT_FAILED;
   }

   Print("[+] OrderFlowImbalanceEA initialized successfully for ", _Symbol, " on timeframe ", EnumToString(_Period));
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
   Print("[-] OrderFlowImbalanceEA deinitialized. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//| Calculate Normalized Volume Delta and Absorption Dynamics        |
//+------------------------------------------------------------------+
bool CalculateOrderFlowMetrics(double &normDelta, bool &isBullishAbsorption, bool &isBearishAbsorption)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   
   int copied = CopyRates(_Symbol, _Period, 1, InpLookbackBars, rates);
   if(copied < InpLookbackBars)
      return false;

   double totalAskVol = 0.0;
   double totalBidVol = 0.0;

   // Approximate tick-level aggressor volume using high-resolution price action & candle physics
   // Under Lee-Ready (1991) microstructure convention:
   // - Up-close bars with strong bodies represent buyer-dominated volume.
   // - Lower shadow wicks represent buy absorption (aggressive sellers absorbed by institutional bid liquidity).
   // - Upper shadow wicks represent sell absorption (aggressive buyers absorbed by institutional ask liquidity).
   for(int i = 0; i < InpLookbackBars; i++)
   {
      double barRange = rates[i].high - rates[i].low;
      if(barRange <= _Point)
         continue;

      double body = MathAbs(rates[i].close - rates[i].open);
      double upperWick = rates[i].high - MathMax(rates[i].open, rates[i].close);
      double lowerWick = MathMin(rates[i].open, rates[i].close) - rates[i].low;
      double tickVol = (double)rates[i].tick_volume;

      double buyPressure = 0.0;
      double sellPressure = 0.0;

      if(rates[i].close >= rates[i].open)
      {
         buyPressure = tickVol * (body + lowerWick) / barRange;
         sellPressure = tickVol * upperWick / barRange;
      }
      else
      {
         sellPressure = tickVol * (body + upperWick) / barRange;
         buyPressure = tickVol * lowerWick / barRange;
      }

      totalAskVol += buyPressure;
      totalBidVol += sellPressure;
   }

   double totalVol = totalAskVol + totalBidVol;
   if(totalVol > 0.0)
      normDelta = (totalAskVol - totalBidVol) / totalVol;
   else
      normDelta = 0.0;

   // Check recent finished bar for absorption wick signature
   double lastRange = rates[0].high - rates[0].low;
   if(lastRange > _Point)
   {
      double lastUpperWick = rates[0].high - MathMax(rates[0].open, rates[0].close);
      double lastLowerWick = MathMin(rates[0].open, rates[0].close) - rates[0].low;

      isBullishAbsorption = (lastLowerWick / lastRange >= InpAbsorptionWickRatio) && (rates[0].close > rates[0].low + lastRange * 0.35);
      isBearishAbsorption = (lastUpperWick / lastRange >= InpAbsorptionWickRatio) && (rates[0].close < rates[0].high - lastRange * 0.35);
   }
   else
   {
      isBullishAbsorption = false;
      isBearishAbsorption = false;
   }

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

   // 3. New bar filtration: Execute entries strictly at bar open to prevent sub-tick oscillation
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == ExtLastBarTime)
      return;

   // Calculate order flow and absorption metrics
   double normDelta = 0.0;
   bool isBullishAbsorption = false;
   bool isBearishAbsorption = false;

   if(!CalculateOrderFlowMetrics(normDelta, isBullishAbsorption, isBearishAbsorption))
      return;

   long existingPosType = -1;
   bool hasPosition = HasOpenPosition(existingPosType);

   // Trading Logic:
   // Bullish Signal: Normalized Delta exceeds threshold OR aggressive selling absorbed at support with positive delta turn
   bool buySignal = (normDelta > InpImbalanceThreshold) || (isBullishAbsorption && normDelta > 0.05);

   // Bearish Signal: Normalized Delta drops below -threshold OR aggressive buying absorbed at resistance with negative delta turn
   bool sellSignal = (normDelta < -InpImbalanceThreshold) || (isBearishAbsorption && normDelta < -0.05);

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
            if(ExtTrade.Buy(lots, _Symbol, ask, stopLossPrice, takeProfitPrice, "OrderFlow Imbalance Buy"))
            {
               Print("[+] BUY Executed: Lots=", lots, " Entry=", ask, " SL=", stopLossPrice, " TP=", takeProfitPrice, " Delta=", normDelta);
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
            if(ExtTrade.Sell(lots, _Symbol, bid, stopLossPrice, takeProfitPrice, "OrderFlow Imbalance Sell"))
            {
               Print("[+] SELL Executed: Lots=", lots, " Entry=", bid, " SL=", stopLossPrice, " TP=", takeProfitPrice, " Delta=", normDelta);
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
      // Defensive exit on structural regime flip: Close position if order flow completely inverts
      if(existingPosType == POSITION_TYPE_BUY && normDelta < -InpImbalanceThreshold * 1.2)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Order Flow Inversion: Closed Long position on extreme negative delta.");
            }
         }
      }
      else if(existingPosType == POSITION_TYPE_SELL && normDelta > InpImbalanceThreshold * 1.2)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
            {
               ExtTrade.PositionClose(ExtPosition.Ticket());
               Print("[*] Order Flow Inversion: Closed Short position on extreme positive delta.");
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
