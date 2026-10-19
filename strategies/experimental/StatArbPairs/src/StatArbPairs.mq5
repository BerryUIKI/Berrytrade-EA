//+------------------------------------------------------------------+
//|                                                 StatArbPairs.mq5 |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                     https://github.com/Berrytrade/Berrytrade-EA  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Inc."
#property link      "https://github.com/Berrytrade/Berrytrade-EA"
#property version   "1.00"
#property description "Statistical Arbitrage Cointegrated Pairs Trading EA (EURUSD vs GBPUSD)"
#property description "Pure native MQL5 implementation with dynamic hedge ratio OLS, Z-score spread tracking, and structural divergence stop-loss."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "=== Pairs & Statistical Parameters ==="
input string   InpSymbolA           = "EURUSD";   // Primary Leg A Symbol
input string   InpSymbolB           = "GBPUSD";   // Hedge Leg B Symbol
input int      InpLookbackBars      = 150;        // Rolling Lookback Window for OLS & Z-Score
input double   InpZEntryThreshold   = 2.0;        // Z-Score Entry Threshold (Standard Deviations)
input double   InpZExitThreshold    = 0.2;        // Z-Score Mean Reversion Exit Threshold
input double   InpZStopThreshold    = 3.5;        // Structural Breakdown Hard Stop Threshold

input group "=== Risk Management ==="
input double   InpRiskPercent       = 1.0;        // Risk Percent Per Spread (% of Account Equity)
input int      InpStopLossPoints    = 250;        // Default Leg Hard Stop Loss fallback (Points)
input int      InpSlippagePoints    = 30;         // Maximum Allowed Slippage (Points)
input ulong    InpMagicNumber       = 107741;     // Magic Number
input string   InpTradeComment      = "StatArb_v1"; // Trade Comment

//--- Global Objects
CTrade         g_trade;
CPositionInfo  g_position;
CAccountInfo   g_account;
CSymbolInfo    g_symbolA;
CSymbolInfo    g_symbolB;

//--- State Tracking
datetime       g_lastBarTime        = 0;
double         g_currentBeta        = 1.0;
double         g_currentZScore      = 0.0;
double         g_meanSpread         = 0.0;
double         g_stdSpread          = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbolA.Name(InpSymbolA))
   {
      PrintFormat("[Error] Failed to initialize CSymbolInfo for Leg A: %s", InpSymbolA);
      return INIT_FAILED;
   }
   if(!g_symbolB.Name(InpSymbolB))
   {
      PrintFormat("[Error] Failed to initialize CSymbolInfo for Leg B: %s", InpSymbolB);
      return INIT_FAILED;
   }

   g_symbolA.Refresh();
   g_symbolB.Refresh();

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePoints);
   g_trade.SetTypeFillingBySymbol(InpSymbolA);

   PrintFormat("[Init] StatArbPairs EA initialized: Pair=[%s, %s], Lookback=%d, Z-Entry=%.2f, Z-Stop=%.2f",
               InpSymbolA, InpSymbolB, InpLookbackBars, InpZEntryThreshold, InpZStopThreshold);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PrintFormat("[Deinit] StatArbPairs EA removed. Reason code: %d", reason);
}

//+------------------------------------------------------------------+
//| Check if a new bar has opened on the chart timeframe             |
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
//| Compute Normalized Lot Size for a Specific Symbol                |
//+------------------------------------------------------------------+
double NormalizeSymbolLots(CSymbolInfo &sym, double rawLots)
{
   sym.Refresh();
   double lotMin  = sym.LotsMin();
   double lotMax  = sym.LotsMax();
   double lotStep = sym.LotsStep();

   if(lotStep <= 0) return lotMin;

   double normalized = MathFloor(rawLots / lotStep) * lotStep;
   if(normalized < lotMin) normalized = lotMin;
   if(normalized > lotMax) normalized = lotMax;

   return normalized;
}

//+------------------------------------------------------------------+
//| Compute Base Capital-at-Risk Lots                                |
//+------------------------------------------------------------------+
double CalculateBaseLots(CSymbolInfo &sym, double stopDistancePoints)
{
   if(stopDistancePoints <= 0) stopDistancePoints = InpStopLossPoints;

   double equity = g_account.Equity();
   double riskAmount = equity * (InpRiskPercent / 100.0) * 0.5; // Split risk across two legs

   sym.Refresh();
   double tickValue = sym.TickValue();
   double tickSize  = sym.TickSize();
   double point     = sym.Point();

   if(tickSize <= 0 || tickValue <= 0 || point <= 0)
      return sym.LotsMin();

   double pointValue = tickValue * (point / tickSize);
   double lossPerLot = stopDistancePoints * pointValue;

   if(lossPerLot <= 0)
      return sym.LotsMin();

   double rawLots = riskAmount / lossPerLot;
   return NormalizeSymbolLots(sym, rawLots);
}

//+------------------------------------------------------------------+
//| Calculate OLS Hedge Ratio Beta and Z-Score of Spread Residuals   |
//+------------------------------------------------------------------+
bool CalculatePairStatistics(double &outBeta, double &outZScore, double &outMean, double &outStd)
{
   int count = InpLookbackBars;
   double closesA[];
   double closesB[];
   ArraySetAsSeries(closesA, true);
   ArraySetAsSeries(closesB, true);

   if(CopyClose(InpSymbolA, _Period, 1, count, closesA) < count ||
      CopyClose(InpSymbolB, _Period, 1, count, closesB) < count)
   {
      return false;
   }

   // Compute log prices and means
   double sumLogA = 0.0, sumLogB = 0.0;
   double logA[];
   double logB[];
   ArrayResize(logA, count);
   ArrayResize(logB, count);

   for(int i = 0; i < count; i++)
   {
      if(closesA[i] <= 0 || closesB[i] <= 0) return false;
      logA[i] = MathLog(closesA[i]);
      logB[i] = MathLog(closesB[i]);
      sumLogA += logA[i];
      sumLogB += logB[i];
   }

   double meanLogA = sumLogA / count;
   double meanLogB = sumLogB / count;

   // Compute Covariance(A, B) and Variance(B) for OLS regression: log(A) = alpha + beta * log(B)
   double covAB = 0.0;
   double varB  = 0.0;
   for(int i = 0; i < count; i++)
   {
      double diffA = logA[i] - meanLogA;
      double diffB = logB[i] - meanLogB;
      covAB += diffA * diffB;
      varB  += diffB * diffB;
   }

   if(varB <= 1e-12) return false;

   double beta = covAB / varB;
   if(beta <= 0) beta = 1.0; // Enforce economic directional co-movement

   // Compute spread residuals S_i = log(A_i) - beta * log(B_i)
   double spread[];
   ArrayResize(spread, count);
   double sumSpread = 0.0;

   for(int i = 0; i < count; i++)
   {
      spread[i] = logA[i] - (beta * logB[i]);
      sumSpread += spread[i];
   }

   double meanSpread = sumSpread / count;

   // Standard deviation of spread
   double sumSqDiff = 0.0;
   for(int i = 0; i < count; i++)
   {
      double diff = spread[i] - meanSpread;
      sumSqDiff += diff * diff;
   }

   double stdSpread = MathSqrt(sumSqDiff / (count - 1));
   if(stdSpread <= 1e-12) return false;

   // Current instantaneous spread on most recent bar close
   double currentSpread = logA[0] - (beta * logB[0]);
   double zScore = (currentSpread - meanSpread) / stdSpread;

   outBeta   = beta;
   outZScore = zScore;
   outMean   = meanSpread;
   outStd    = stdSpread;

   return true;
}

//+------------------------------------------------------------------+
//| Check if open positions exist for this strategy                  |
//+------------------------------------------------------------------+
int CountOpenPositions(int &legATickets, int &legBTickets)
{
   legATickets = 0;
   legBTickets = 0;
   int total = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Magic() == InpMagicNumber)
         {
            if(g_position.Symbol() == InpSymbolA) legATickets++;
            if(g_position.Symbol() == InpSymbolB) legBTickets++;
            total++;
         }
      }
   }
   return total;
}

//+------------------------------------------------------------------+
//| Close all open spread positions across both legs                 |
//+------------------------------------------------------------------+
void CloseSpreadPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Magic() == InpMagicNumber &&
            (g_position.Symbol() == InpSymbolA || g_position.Symbol() == InpSymbolB))
         {
            PrintFormat("[Pair Close] Closing #%d (%s, %s). Reason: %s",
                        g_position.Ticket(), g_position.Symbol(),
                        EnumToString(g_position.PositionType()), reason);
            g_trade.SetTypeFillingBySymbol(g_position.Symbol());
            g_trade.PositionClose(g_position.Ticket());
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

   double beta = 1.0, zScore = 0.0, meanSpread = 0.0, stdSpread = 0.0;
   if(!CalculatePairStatistics(beta, zScore, meanSpread, stdSpread))
      return;

   g_currentBeta   = beta;
   g_currentZScore = zScore;
   g_meanSpread    = meanSpread;
   g_stdSpread     = stdSpread;

   int legA = 0, legB = 0;
   int totalPositions = CountOpenPositions(legA, legB);

   // 1. Position Management: Mean Reversion Exit or Structural Breakdown Stop
   if(totalPositions > 0)
   {
      // Mean reversion target reached
      if(MathAbs(zScore) <= InpZExitThreshold)
      {
         CloseSpreadPositions(StringFormat("Mean reversion convergence achieved (Z=%.2f)", zScore));
         return;
      }

      // Structural divergence stop-loss: cointegration breakdown
      if(MathAbs(zScore) >= InpZStopThreshold)
      {
         CloseSpreadPositions(StringFormat("Structural breakdown divergence stop triggered (Z=%.2f)", zScore));
         return;
      }
      return; // Hold active spread position
   }

   // 2. Entry Logic: Statistical Outlier Arbitrage
   double lotsA = CalculateBaseLots(g_symbolA, InpStopLossPoints);
   double rawLotsB = lotsA * beta;
   double lotsB = NormalizeSymbolLots(g_symbolB, rawLotsB);

   // Condition A: Spread is overextended UPWARD (Z > +EntryThreshold)
   // Spread = log(A) - beta * log(B) is too high => Short Leg A, Long Leg B
   if(zScore >= InpZEntryThreshold)
   {
      g_symbolA.Refresh();
      g_symbolB.Refresh();
      double bidA = g_symbolA.Bid();
      double askB = g_symbolB.Ask();

      double slA = bidA + (InpStopLossPoints * g_symbolA.Point());
      double slB = askB - (InpStopLossPoints * g_symbolB.Point());

      PrintFormat("[Signal] Overextended High Spread (Z=%.2f >= %.2f). Executing SHORT %s (%.2f lots) / LONG %s (%.2f lots, Beta=%.2f)",
                  zScore, InpZEntryThreshold, InpSymbolA, lotsA, InpSymbolB, lotsB, beta);

      g_trade.SetTypeFillingBySymbol(InpSymbolA);
      bool sellA = g_trade.Sell(lotsA, InpSymbolA, bidA, slA, 0.0, InpTradeComment);

      g_trade.SetTypeFillingBySymbol(InpSymbolB);
      bool buyB  = g_trade.Buy(lotsB, InpSymbolB, askB, slB, 0.0, InpTradeComment);

      if(!sellA || !buyB)
      {
         PrintFormat("[Warning] Incomplete spread execution. SellA=%d, BuyB=%d. Unwinding legs if needed.", sellA, buyB);
      }
   }
   // Condition B: Spread is overextended DOWNWARD (Z < -EntryThreshold)
   // Spread = log(A) - beta * log(B) is too low => Long Leg A, Short Leg B
   else if(zScore <= -InpZEntryThreshold)
   {
      g_symbolA.Refresh();
      g_symbolB.Refresh();
      double askA = g_symbolA.Ask();
      double bidB = g_symbolB.Bid();

      double slA = askA - (InpStopLossPoints * g_symbolA.Point());
      double slB = bidB + (InpStopLossPoints * g_symbolB.Point());

      PrintFormat("[Signal] Overextended Low Spread (Z=%.2f <= -%.2f). Executing LONG %s (%.2f lots) / SHORT %s (%.2f lots, Beta=%.2f)",
                  zScore, InpZEntryThreshold, InpSymbolA, lotsA, InpSymbolB, lotsB, beta);

      g_trade.SetTypeFillingBySymbol(InpSymbolA);
      bool buyA  = g_trade.Buy(lotsA, InpSymbolA, askA, slA, 0.0, InpTradeComment);

      g_trade.SetTypeFillingBySymbol(InpSymbolB);
      bool sellB = g_trade.Sell(lotsB, InpSymbolB, bidB, slB, 0.0, InpTradeComment);

      if(!buyA || !sellB)
      {
         PrintFormat("[Warning] Incomplete spread execution. BuyA=%d, SellB=%d. Unwinding legs if needed.", buyA, sellB);
      }
   }
}
//+------------------------------------------------------------------+
