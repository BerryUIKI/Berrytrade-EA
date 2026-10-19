//+------------------------------------------------------------------+
//|                                                   TemplateEA.mq5 |
//|                                  Copyright 2026, Berrytrade Community |
//|                                              https://berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Community"
#property link      "https://github.com/BerryUIKI/Berrytrade-EA"
#property version   "1.00"
#property description "Reference EA implementation for the Berrytrade-EA repository."

#include <Trade\Trade.mqh>
#include <Berrytrade\Defines.mqh>
#include <Berrytrade\TradeRisk.mqh>

//--- Input parameters
input group "=== Strategy Parameters ==="
input ulong   InpMagicNumber       = 100101;     // Magic Number
input int     InpFastPeriod        = 10;         // Fast EMA Period
input int     InpSlowPeriod        = 30;         // Slow EMA Period

input group "=== Risk Management ==="
input double  InpRiskPercent       = 0.5;        // Risk per trade (% of Equity)
input double  InpStopLossPoints    = 150.0;      // Hard Stop Loss (Points)
input double  InpTakeProfitPoints  = 300.0;      // Take Profit (Points)
input double  InpMaxSpreadPoints   = 30.0;       // Maximum Allowed Spread (Points)
input bool    InpCloseBeforeWeekend= true;       // Close positions before weekend

//--- Global handles and objects
CTrade         g_trade;
int            g_handleFastEMA = INVALID_HANDLE;
int            g_handleSlowEMA = INVALID_HANDLE;
datetime       g_lastBarTime   = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);

   // Initialize Indicator handles
   g_handleFastEMA = iMA(_Symbol, _Period, InpFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleSlowEMA = iMA(_Symbol, _Period, InpSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);

   if(g_handleFastEMA == INVALID_HANDLE || g_handleSlowEMA == INVALID_HANDLE)
   {
      Print("[Error] Failed to initialize indicator handles.");
      return INIT_FAILED;
   }

   PrintFormat("[Init] %s initialized successfully on %s (%s). Magic: %I64u", 
               __FILE__, _Symbol, EnumToString(_Period), InpMagicNumber);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_handleFastEMA != INVALID_HANDLE)
      IndicatorRelease(g_handleFastEMA);
   if(g_handleSlowEMA != INVALID_HANDLE)
      IndicatorRelease(g_handleSlowEMA);

   PrintFormat("[Deinit] %s unloaded. Reason code: %d", __FILE__, reason);
}

//+------------------------------------------------------------------+
//| Helper: Check if new bar has opened                              |
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
//| Helper: Check count of open positions for this EA                |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check spread filter
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPoints)
      return;

   // Weekend closure safeguard
   if(InpCloseBeforeWeekend)
   {
      MqlDateTime dt;
      TimeCurrent(dt);
      if(dt.day_of_week == 5 && dt.hour >= 21) // Friday evening close
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
               g_trade.PositionClose(PositionGetTicket(i));
         }
         return;
      }
   }

   // Evaluate signals strictly on bar close to prevent intrabar noise
   if(!IsNewBar())
      return;

   double fastMA[2], slowMA[2];
   if(CopyBuffer(g_handleFastEMA, 0, 1, 2, fastMA) < 2 || CopyBuffer(g_handleSlowEMA, 0, 1, 2, slowMA) < 2)
      return;

   bool buySignal  = (fastMA[0] <= slowMA[0] && fastMA[1] > slowMA[1]);
   bool sellSignal = (fastMA[0] >= slowMA[0] && fastMA[1] < slowMA[1]);

   if(CountOpenPositions() == 0)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      double lotSize = CTradeRiskManager::CalculateLotSize(_Symbol, InpRiskPercent, InpStopLossPoints);

      if(buySignal)
      {
         double sl = ask - (InpStopLossPoints * point);
         double tp = (InpTakeProfitPoints > 0) ? (ask + InpTakeProfitPoints * point) : 0.0;

         if(CTradeRiskManager::CheckStopLossValid(_Symbol, ORDER_TYPE_BUY, ask, sl))
         {
            g_trade.Buy(lotSize, _Symbol, ask, sl, tp, "Berrytrade-TemplateEA-Buy");
         }
      }
      else if(sellSignal)
      {
         double sl = bid + (InpStopLossPoints * point);
         double tp = (InpTakeProfitPoints > 0) ? (bid - InpTakeProfitPoints * point) : 0.0;

         if(CTradeRiskManager::CheckStopLossValid(_Symbol, ORDER_TYPE_SELL, bid, sl))
         {
            g_trade.Sell(lotSize, _Symbol, bid, sl, tp, "Berrytrade-TemplateEA-Sell");
         }
      }
   }
}
