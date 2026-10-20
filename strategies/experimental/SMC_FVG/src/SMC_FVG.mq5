//+------------------------------------------------------------------+
//|                                                      SMC_FVG.mq5 |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                     https://github.com/Berrytrade/Berrytrade-EA  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Inc."
#property link      "https://github.com/Berrytrade/Berrytrade-EA"
#property version   "1.00"
#property description "Smart Money Concepts (SMC) Fair Value Gap (FVG) and Liquidity Imbalance EA"
#property description "Pure native MQL5 implementation with institutional risk sizing, hard stop-loss, and no loss averaging."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "=== SMC / FVG Parameters ==="
input int      InpMinGapPoints       = 100;        // Minimum FVG Gap Size (Points)
input int      InpMaxLookbackBars    = 30;         // Maximum Lookback for Unmitigated FVGs
input double   InpMinDisplacementATR = 1.2;        // Min Displacement Candle Body vs ATR(14)
input int      InpATRPeriod          = 14;         // ATR Filter Period
input double   InpRiskRewardRatio    = 2.0;        // Take Profit Risk-to-Reward Ratio
input bool     InpUseMidpointEntry   = true;       // Entry at 50% Consequent Encroachment (CE)

input group "=== Risk Management ==="
input double   InpRiskPercent        = 1.0;        // Risk Percent Per Trade (% of Account Equity)
input int      InpStopLossPoints     = 200;        // Default Hard Stop Loss fallback (Points)
input int      InpBufferPoints       = 20;         // Stop Loss Safety Buffer beyond Swing/Origin (Points)
input int      InpSlippagePoints     = 30;         // Maximum Allowed Slippage (Points)
input ulong    InpMagicNumber        = 109931;     // Magic Number
input string   InpTradeComment       = "SMC_FVG_v1"; // Trade Comment

//--- Structure for tracking Fair Value Gaps
struct SFairValueGap
{
   bool        isBullish;      // True if Bullish FVG, False if Bearish
   double      top;            // Upper boundary of imbalance
   double      bottom;         // Lower boundary of imbalance
   double      midpoint;       // Consequent Encroachment (50%)
   double      invalidationSL; // Hard Stop Loss level (origin bar extreme)
   datetime    barTime;        // Time of the displacement bar
   bool        mitigated;      // True if price has entered and filled the gap
};

//--- Global Objects
CTrade         g_trade;
CPositionInfo  g_position;
CAccountInfo   g_account;
CSymbolInfo    g_symbol;
int            g_atrHandle           = INVALID_HANDLE;
datetime       g_lastBarTime         = 0;

//--- State Tracking
SFairValueGap  g_activeFVGs[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbol.Name(_Symbol))
   {
      Print("[Error] Failed to initialize CSymbolInfo for ", _Symbol);
      return INIT_FAILED;
   }
   
   g_symbol.Refresh();
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePoints);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   g_atrHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
   {
      Print("[Error] Failed to create ATR indicator handle.");
      return INIT_FAILED;
   }

   ArrayResize(g_activeFVGs, 0);

   PrintFormat("[Init] SMC_FVG EA initialized on %s (Digits=%d, Point=%.5f, ATR=%d)",
               _Symbol, g_symbol.Digits(), g_symbol.Point(), InpATRPeriod);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_atrHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_atrHandle);
      g_atrHandle = INVALID_HANDLE;
   }
   PrintFormat("[Deinit] SMC_FVG EA removed. Reason: %d", reason);
}

//+------------------------------------------------------------------+
//| Check if a new bar has opened                                    |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check for open positions belonging to this EA                    |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Symbol() == _Symbol && g_position.Magic() == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Institutional Lot Size Calculation with Symbol Constraint Limits |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossDistancePoints)
{
   if(stopLossDistancePoints <= 0)
      stopLossDistancePoints = InpStopLossPoints;

   double equity = g_account.Equity();
   double riskAmount = equity * (InpRiskPercent / 100.0);

   g_symbol.Refresh();
   double tickValue = g_symbol.TickValue();
   double tickSize  = g_symbol.TickSize();
   double point     = g_symbol.Point();

   if(tickSize <= 0 || tickValue <= 0 || point <= 0)
   {
      Print("[Warning] Invalid tick properties. Falling back to LotsMin.");
      return g_symbol.LotsMin();
   }

   double pointValue = tickValue * (point / tickSize);
   double lossPerLot = stopLossDistancePoints * pointValue;

   if(lossPerLot <= 0)
      return g_symbol.LotsMin();

   double rawLots = riskAmount / lossPerLot;

   double lotMin  = g_symbol.LotsMin();
   double lotMax  = g_symbol.LotsMax();
   double lotStep = g_symbol.LotsStep();

   double normalizedLots = MathFloor(rawLots / lotStep) * lotStep;

   if(normalizedLots < lotMin) normalizedLots = lotMin;
   if(normalizedLots > lotMax) normalizedLots = lotMax;

   return normalizedLots;
}

//+------------------------------------------------------------------+
//| Scan for 3-Bar Fair Value Gaps across recent bars                |
//+------------------------------------------------------------------+
void ScanForFairValueGaps()
{
   int requiredBars = InpMaxLookbackBars + 5;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(_Symbol, _Period, 0, requiredBars, rates) < requiredBars)
      return;

   double atrValues[];
   ArraySetAsSeries(atrValues, true);
   if(CopyBuffer(g_atrHandle, 0, 0, requiredBars, atrValues) < requiredBars)
      return;

   ArrayResize(g_activeFVGs, 0);

   double minGapDist = InpMinGapPoints * _Point;

   // Evaluate 3-bar sequences: bar i+2 (candle 1), bar i+1 (candle 2, displacement), bar i (candle 3)
   for(int i = 1; i <= InpMaxLookbackBars; i++)
   {
      int bar1 = i + 2;
      int bar2 = i + 1; // Displacement candle
      int bar3 = i;

      double bodySize = MathAbs(rates[bar2].close - rates[bar2].open);
      double currentATR = atrValues[bar2];

      // Displacement filter: candle body must exceed ATR multiple
      if(bodySize < (InpMinDisplacementATR * currentATR))
         continue;

      // 1. Bullish Fair Value Gap: Bar 1 High < Bar 3 Low
      if(rates[bar2].close > rates[bar2].open && rates[bar1].high < rates[bar3].low)
      {
         double gapSize = rates[bar3].low - rates[bar1].high;
         if(gapSize >= minGapDist)
         {
            // Check if mitigated by any subsequent bars between bar3 and bar 0
            bool mitigated = false;
            for(int k = bar3 - 1; k >= 1; k--)
            {
               if(rates[k].low <= rates[bar1].high)
               {
                  mitigated = true;
                  break;
               }
            }

            if(!mitigated)
            {
               int size = ArraySize(g_activeFVGs);
               ArrayResize(g_activeFVGs, size + 1);
               g_activeFVGs[size].isBullish      = true;
               g_activeFVGs[size].top            = rates[bar3].low;
               g_activeFVGs[size].bottom         = rates[bar1].high;
               g_activeFVGs[size].midpoint       = (g_activeFVGs[size].top + g_activeFVGs[size].bottom) * 0.5;
               g_activeFVGs[size].invalidationSL = rates[bar1].low - (InpBufferPoints * _Point);
               g_activeFVGs[size].barTime        = rates[bar2].time;
               g_activeFVGs[size].mitigated      = false;
            }
         }
      }
      // 2. Bearish Fair Value Gap: Bar 1 Low > Bar 3 High
      else if(rates[bar2].close < rates[bar2].open && rates[bar1].low > rates[bar3].high)
      {
         double gapSize = rates[bar1].low - rates[bar3].high;
         if(gapSize >= minGapDist)
         {
            bool mitigated = false;
            for(int k = bar3 - 1; k >= 1; k--)
            {
               if(rates[k].high >= rates[bar1].low)
               {
                  mitigated = true;
                  break;
               }
            }

            if(!mitigated)
            {
               int size = ArraySize(g_activeFVGs);
               ArrayResize(g_activeFVGs, size + 1);
               g_activeFVGs[size].isBullish      = false;
               g_activeFVGs[size].top            = rates[bar1].low;
               g_activeFVGs[size].bottom         = rates[bar3].high;
               g_activeFVGs[size].midpoint       = (g_activeFVGs[size].top + g_activeFVGs[size].bottom) * 0.5;
               g_activeFVGs[size].invalidationSL = rates[bar1].high + (InpBufferPoints * _Point);
               g_activeFVGs[size].barTime        = rates[bar2].time;
               g_activeFVGs[size].mitigated      = false;
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
   if(!IsNewBar())
      return;

   if(HasOpenPosition())
      return;

   ScanForFairValueGaps();

   int totalFVGs = ArraySize(g_activeFVGs);
   if(totalFVGs <= 0)
      return;

   MqlRates currentRates[];
   ArraySetAsSeries(currentRates, true);
   if(CopyRates(_Symbol, _Period, 1, 1, currentRates) < 1)
      return;

   double prevClose = currentRates[0].close;
   double prevLow   = currentRates[0].low;
   double prevHigh  = currentRates[0].high;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Check mitigation of the most recent unmitigated FVG
   for(int i = 0; i < totalFVGs; i++)
   {
      // Bullish Mitigation: Price dipped into the Bullish FVG zone
      if(g_activeFVGs[i].isBullish)
      {
         double triggerLevel = InpUseMidpointEntry ? g_activeFVGs[i].midpoint : g_activeFVGs[i].top;

         if(prevLow <= triggerLevel && prevClose >= g_activeFVGs[i].bottom)
         {
            double stopLoss = g_activeFVGs[i].invalidationSL;
            double slDistancePoints = (ask - stopLoss) / _Point;

            if(slDistancePoints > 0)
            {
               double lots = CalculateLotSize(slDistancePoints);
               double takeProfit = ask + (slDistancePoints * InpRiskRewardRatio * _Point);

               if(g_trade.Buy(lots, _Symbol, ask, stopLoss, takeProfit, InpTradeComment))
               {
                  PrintFormat("[Execution] BUY SMC_FVG %s | Lots=%.2f, Price=%.5f, SL=%.5f, TP=%.5f (FVG Top=%.5f, Mid=%.5f)",
                              _Symbol, lots, ask, stopLoss, takeProfit, g_activeFVGs[i].top, g_activeFVGs[i].midpoint);
                  return;
               }
               else
               {
                  PrintFormat("[Error] Buy rejected. Code: %d", g_trade.ResultRetcode());
               }
            }
         }
      }
      // Bearish Mitigation: Price rallied into the Bearish FVG zone
      else
      {
         double triggerLevel = InpUseMidpointEntry ? g_activeFVGs[i].midpoint : g_activeFVGs[i].bottom;

         if(prevHigh >= triggerLevel && prevClose <= g_activeFVGs[i].top)
         {
            double stopLoss = g_activeFVGs[i].invalidationSL;
            double slDistancePoints = (stopLoss - bid) / _Point;

            if(slDistancePoints > 0)
            {
               double lots = CalculateLotSize(slDistancePoints);
               double takeProfit = bid - (slDistancePoints * InpRiskRewardRatio * _Point);

               if(g_trade.Sell(lots, _Symbol, bid, stopLoss, takeProfit, InpTradeComment))
               {
                  PrintFormat("[Execution] SELL SMC_FVG %s | Lots=%.2f, Price=%.5f, SL=%.5f, TP=%.5f (FVG Bot=%.5f, Mid=%.5f)",
                              _Symbol, lots, bid, stopLoss, takeProfit, g_activeFVGs[i].bottom, g_activeFVGs[i].midpoint);
                  return;
               }
               else
               {
                  PrintFormat("[Error] Sell rejected. Code: %d", g_trade.ResultRetcode());
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
