//+------------------------------------------------------------------+
//|                                               LondonBreakout.mq5 |
//|                                  Copyright 2026, Berrytrade Inc. |
//|                     https://github.com/Berrytrade/Berrytrade-EA  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Inc."
#property link      "https://github.com/Berrytrade/Berrytrade-EA"
#property version   "1.00"
#property description "London Open Breakout Strategy (Asian Session Box Liquidity Expansion)"
#property description "Pure native MQL5 implementation with dynamic risk sizing, hard stop-loss, and zero overnight carryover."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "=== Strategy Parameters ==="
input int      InpAsianStartHour    = 0;          // Asian Session Start Hour (Broker Time)
input int      InpAsianStartMin     = 0;          // Asian Session Start Minute
input int      InpAsianEndHour      = 7;          // Asian Session End Hour (Broker Time)
input int      InpAsianEndMin       = 0;          // Asian Session End Minute
input int      InpTradeStartHour    = 7;          // Trading Window Start Hour
input int      InpTradeEndHour      = 13;         // Trading Window End Hour (No new entries after)
input int      InpSessionCloseHour  = 19;         // Intraday Session Close Hour (Flat before rollover)
input int      InpSessionCloseMin   = 0;          // Intraday Session Close Minute
input int      InpBufferPoints      = 30;         // Breakout Buffer (Points above/below box)
input int      InpMinBoxPoints      = 150;        // Minimum Asian Box Height (Points)
input int      InpMaxBoxPoints      = 800;        // Maximum Asian Box Height (Points)
input double   InpRiskRewardRatio   = 1.5;        // Take Profit Risk-to-Reward Ratio (vs Stop Distance)

input group "=== Risk Management ==="
input double   InpRiskPercent       = 1.0;        // Risk Percent Per Trade (% of Account Equity)
input int      InpStopLossPoints    = 250;        // Default Hard Stop Loss fallback (Points)
input bool     InpUseBoxOppositeSL  = true;       // Use Opposite Box Boundary as Stop Loss
input int      InpSlippagePoints    = 30;         // Maximum Allowed Slippage (Points)
input ulong    InpMagicNumber       = 108821;     // Magic Number
input string   InpTradeComment      = "LondonBreakout_v1"; // Trade Comment

//--- Global Objects
CTrade         g_trade;
CPositionInfo  g_position;
CAccountInfo   g_account;
CSymbolInfo    g_symbol;

//--- State Tracking
datetime       g_lastTradeDate      = 0;
datetime       g_lastBoxDate        = 0;
double         g_boxHigh            = 0.0;
double         g_boxLow             = 0.0;
bool           g_boxValid           = false;
datetime       g_lastBarTime        = 0;

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

   PrintFormat("[Init] LondonBreakout EA initialized successfully on %s (Digits=%d, Point=%.5f)",
               _Symbol, g_symbol.Digits(), g_symbol.Point());
   PrintFormat("[Init] Asian Range: %02d:%02d - %02d:%02d | Trade Window: %02d:00 - %02d:00 | Close: %02d:%02d",
               InpAsianStartHour, InpAsianStartMin, InpAsianEndHour, InpAsianEndMin,
               InpTradeStartHour, InpTradeEndHour, InpSessionCloseHour, InpSessionCloseMin);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PrintFormat("[Deinit] LondonBreakout EA removed. Reason code: %d", reason);
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
//| Calculate Asian Session Box High and Low                         |
//+------------------------------------------------------------------+
bool CalculateAsianBox(datetime currentTime, double &boxHigh, double &boxLow)
{
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   // Form Asian session start and end datetimes for today
   MqlDateTime dtStart = dt;
   dtStart.hour = InpAsianStartHour;
   dtStart.min  = InpAsianStartMin;
   dtStart.sec  = 0;
   datetime startTime = StructToTime(dtStart);

   MqlDateTime dtEnd = dt;
   dtEnd.hour = InpAsianEndHour;
   dtEnd.min  = InpAsianEndMin;
   dtEnd.sec  = 0;
   datetime endTime = StructToTime(dtEnd);

   // Check if we are past the Asian session end
   if(currentTime < endTime)
   {
      return false; // Still within or before Asian session
   }

   // Find bar indices corresponding to the Asian session
   int startBar = iBarShift(_Symbol, _Period, startTime, false);
   int endBar   = iBarShift(_Symbol, _Period, endTime, false);

   if(startBar < 0 || endBar < 0 || endBar > startBar)
   {
      return false;
   }

   int count = startBar - endBar + 1;
   if(count <= 0) return false;

   double highs[];
   double lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);

   if(CopyHigh(_Symbol, _Period, endBar, count, highs) <= 0 ||
      CopyLow(_Symbol, _Period, endBar, count, lows) <= 0)
   {
      return false;
   }

   boxHigh = highs[ArrayMaximum(highs, 0, count)];
   boxLow  = lows[ArrayMinimum(lows, 0, count)];

   return true;
}

//+------------------------------------------------------------------+
//| Compute Institutional Sized Volume with Broker Constraints       |
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
      Print("[Warning] Invalid tick properties. Falling back to minimum volume.");
      return g_symbol.LotsMin();
   }

   // Loss per 1.0 standard lot over stop distance
   double pointValue = tickValue * (point / tickSize);
   double lossPerLot = stopLossDistancePoints * pointValue;

   if(lossPerLot <= 0)
      return g_symbol.LotsMin();

   double rawLots = riskAmount / lossPerLot;

   // Enforce broker symbol constraints
   double lotMin  = g_symbol.LotsMin();
   double lotMax  = g_symbol.LotsMax();
   double lotStep = g_symbol.LotsStep();

   double normalizedLots = MathFloor(rawLots / lotStep) * lotStep;

   if(normalizedLots < lotMin) normalizedLots = lotMin;
   if(normalizedLots > lotMax) normalizedLots = lotMax;

   return normalizedLots;
}

//+------------------------------------------------------------------+
//| Check if open positions exist for this EA                        |
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
//| Close all open positions for this EA (Session Exit)              |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Symbol() == _Symbol && g_position.Magic() == InpMagicNumber)
         {
            PrintFormat("[Session Exit] Closing position #%d (%s) at market. Reason: %s",
                        g_position.Ticket(), EnumToString(g_position.PositionType()), reason);
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
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

   // 1. Session Close Check: Force-flat before rollover swap
   if(dt.hour > InpSessionCloseHour || (dt.hour == InpSessionCloseHour && dt.min >= InpSessionCloseMin))
   {
      if(HasOpenPosition())
      {
         CloseAllPositions("Intraday session close window reached");
      }
      return;
   }

   // 2. Bar Timing: Only execute entry logic on new bar to avoid intra-bar whipsaw
   if(!IsNewBar())
   {
      return;
   }

   // 3. Update Asian Box Range once per day
   datetime todayDate = currentTime - (currentTime % 86400);
   if(g_lastBoxDate != todayDate)
   {
      double h = 0.0, l = 0.0;
      if(CalculateAsianBox(currentTime, h, l))
      {
         double boxRangePoints = (h - l) / _Point;
         if(boxRangePoints >= InpMinBoxPoints && boxRangePoints <= InpMaxBoxPoints)
         {
            g_boxHigh = h;
            g_boxLow = l;
            g_boxValid = true;
            g_lastBoxDate = todayDate;
            PrintFormat("[Box Definition] Valid Asian Box: High=%.5f, Low=%.5f, Range=%.1f pts",
                        g_boxHigh, g_boxLow, boxRangePoints);
         }
         else
         {
            g_boxValid = false;
            PrintFormat("[Box Filter] Asian Box Range %.1f pts out of bounds [%d, %d]. Skipped today.",
                        boxRangePoints, InpMinBoxPoints, InpMaxBoxPoints);
         }
      }
   }

   // 4. Check if today's trade already completed
   if(g_lastTradeDate == todayDate)
   {
      return; // Single trade per day enforced
   }

   // 5. Entry Window Filter: Must be within trading hours
   if(dt.hour < InpTradeStartHour || dt.hour >= InpTradeEndHour)
   {
      return;
   }

   if(!g_boxValid || HasOpenPosition())
   {
      return;
   }

   // 6. Breakout Detection on Completed Bar Close
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2)
      return;

   double prevClose = rates[0].close;
   double buffer = InpBufferPoints * _Point;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Bullish Breakout: Prior bar closed above Asian Box High + Buffer
   if(prevClose > (g_boxHigh + buffer))
   {
      double stopLoss = InpUseBoxOppositeSL ? g_boxLow : (ask - InpStopLossPoints * _Point);
      double slPoints = (ask - stopLoss) / _Point;

      if(slPoints > 0)
      {
         double lots = CalculateLotSize(slPoints);
         double takeProfit = ask + (slPoints * InpRiskRewardRatio * _Point);

         if(g_trade.Buy(lots, _Symbol, ask, stopLoss, takeProfit, InpTradeComment))
         {
            PrintFormat("[Execution] BUY %s | Lots=%.2f, Price=%.5f, SL=%.5f, TP=%.5f (Box High=%.5f)",
                        _Symbol, lots, ask, stopLoss, takeProfit, g_boxHigh);
            g_lastTradeDate = todayDate;
         }
         else
         {
            PrintFormat("[Error] Buy order rejected. Code: %d", g_trade.ResultRetcode());
         }
      }
   }
   // Bearish Breakout: Prior bar closed below Asian Box Low - Buffer
   else if(prevClose < (g_boxLow - buffer))
   {
      double stopLoss = InpUseBoxOppositeSL ? g_boxHigh : (bid + InpStopLossPoints * _Point);
      double slPoints = (stopLoss - bid) / _Point;

      if(slPoints > 0)
      {
         double lots = CalculateLotSize(slPoints);
         double takeProfit = bid - (slPoints * InpRiskRewardRatio * _Point);

         if(g_trade.Sell(lots, _Symbol, bid, stopLoss, takeProfit, InpTradeComment))
         {
            PrintFormat("[Execution] SELL %s | Lots=%.2f, Price=%.5f, SL=%.5f, TP=%.5f (Box Low=%.5f)",
                        _Symbol, lots, bid, stopLoss, takeProfit, g_boxLow);
            g_lastTradeDate = todayDate;
         }
         else
         {
            PrintFormat("[Error] Sell order rejected. Code: %d", g_trade.ResultRetcode());
         }
      }
   }
}
//+------------------------------------------------------------------+
