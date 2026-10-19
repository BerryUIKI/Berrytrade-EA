//+------------------------------------------------------------------+
//|                                                 TurtleTrader.mq5 |
//|                                  Copyright 2026, Berrytrade Quantitative Research |
//|                                        https://github.com/BerryUIKI/Berrytrade-EA |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Berrytrade Quantitative Research"
#property link        "https://github.com/BerryUIKI/Berrytrade-EA"
#property version     "1.00"
#property description "Classic Turtle Trading System: Donchian Breakout with N-ATR Volatility Sizing, 2N Hard Stop Loss, and Dynamic Pyramiding."
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Enums
enum ENUM_TURTLE_SYSTEM
  {
   SYSTEM_1_SHORT_TERM = 1, // System 1 (20-Day Entry, 10-Day Exit)
   SYSTEM_2_LONG_TERM  = 2  // System 2 (55-Day Entry, 20-Day Exit)
  };

//--- Input Parameters
input group "=== System Strategy Configuration ==="
input ENUM_TURTLE_SYSTEM InpSystemMode          = SYSTEM_1_SHORT_TERM; // Trading System Mode
input int                InpCustomEntryPeriod   = 20;                  // Custom Entry Breakout Period (Bars)
input int                InpCustomExitPeriod    = 10;                  // Custom Exit Breakout Period (Bars)
input int                InpATRPeriod           = 20;                  // Volatility ATR Period (N calculation)

input group "=== Capital Risk & Position Sizing ==="
input double             InpRiskPercent         = 1.0;                 // Risk Percent per Unit (%)
input int                InpMaxUnits            = 4;                   // Maximum Pyramiding Units (1 = No pyramiding)
input double             InpPyramidStepN        = 0.5;                 // Pyramiding Step in Multiples of N
input double             InpStopLossN           = 2.0;                 // Hard Stop Loss in Multiples of N

input group "=== Execution & Order Constraints ==="
input ulong              InpMagicNumber         = 101984;              // Magic Number
input ulong              InpSlippagePoints      = 30;                  // Maximum Allowed Slippage (Points)
input string             InpTradeComment        = "Berrytrade_Turtle"; // Trade Execution Comment

//--- Global Objects
CTrade         ExtTrade;
CPositionInfo  ExtPosition;
CSymbolInfo    ExtSymbol;
CAccountInfo   ExtAccount;

//--- Indicator Handles
int            ExtHandleATR = INVALID_HANDLE;

//--- State Tracking
datetime       ExtLastBarTime = 0;

//+------------------------------------------------------------------+
//| Helper: Normalize Volume to Broker Lot Step & Minimums           |
//+------------------------------------------------------------------+
double NormalizeLot(double volume)
  {
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step_lot <= 0.0)
      step_lot = 0.01;

   double normalized = MathFloor(volume / step_lot) * step_lot;
   if(normalized < min_lot)
      normalized = min_lot;
   if(normalized > max_lot)
      normalized = max_lot;

   int digits = (step_lot >= 0.1) ? 1 : ((step_lot >= 0.01) ? 2 : 3);
   return NormalizeDouble(normalized, digits);
  }

//+------------------------------------------------------------------+
//| Calculate Turtle N (ATR Volatility in Price Units)               |
//+------------------------------------------------------------------+
double GetCurrentN()
  {
   if(ExtHandleATR == INVALID_HANDLE)
      return 0.0;

   double atr_val[1];
   if(CopyBuffer(ExtHandleATR, 0, 1, 1, atr_val) <= 0)
     {
      Print("[-] Error reading ATR buffer: ", GetLastError());
      return 0.0;
     }

   return atr_val[0];
  }

//+------------------------------------------------------------------+
//| Calculate Single Unit Position Size Based on 1% Capital Risk / N |
//+------------------------------------------------------------------+
double CalculateUnitSize(double N)
  {
   if(N <= 0.0)
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double equity       = ExtAccount.Equity();
   double dollar_risk  = equity * (InpRiskPercent / 100.0);
   double tick_value   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size    = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_size <= 0.0 || tick_value <= 0.0)
     {
      double point_val = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if(point_val > 0.0)
         tick_value = point_val * 100000.0; // Fallback approximation
      tick_size = point_val;
     }

   double points_in_N = N / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double value_per_point_per_lot = (tick_size > 0.0) ? (tick_value / tick_size * SymbolInfoDouble(_Symbol, SYMBOL_POINT)) : 1.0;
   double dollar_volatility_per_lot = points_in_N * value_per_point_per_lot;

   if(dollar_volatility_per_lot <= 0.0)
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double unit_lots = dollar_risk / dollar_volatility_per_lot;
   return NormalizeLot(unit_lots);
  }

//+------------------------------------------------------------------+
//| Get Donchian Highest High and Lowest Low over Specified Period   |
//+------------------------------------------------------------------+
bool GetDonchianChannel(int period, double &highest_high, double &lowest_low)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   // Shift 1 to ignore the current live forming bar
   if(CopyRates(_Symbol, _Period, 1, period, rates) < period)
     {
      Print("[-] Insufficient historical rates copied for Donchian channel.");
      return false;
     }

   highest_high = rates[0].high;
   lowest_low   = rates[0].low;

   for(int i = 1; i < period; i++)
     {
      if(rates[i].high > highest_high)
         highest_high = rates[i].high;
      if(rates[i].low < lowest_low)
         lowest_low = rates[i].low;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialize Symbols and Account Helpers
   if(!ExtSymbol.Name(_Symbol))
     {
      Print("[-] Failed to initialize symbol: ", _Symbol);
      return INIT_FAILED;
     }
   ExtSymbol.Refresh();

   ExtTrade.SetExpertMagicNumber(InpMagicNumber);
   ExtTrade.SetDeviationInPoints(InpSlippagePoints);
   ExtTrade.SetTypeFilling(ORDER_FILLING_IOC);

   // Configure ATR handle
   ExtHandleATR = iATR(_Symbol, _Period, InpATRPeriod);
   if(ExtHandleATR == INVALID_HANDLE)
     {
      Print("[-] Failed to create ATR handle for N-volatility calculation.");
      return INIT_FAILED;
     }

   Print("[+] TurtleTrader initialized successfully on ", _Symbol, " timeframe: ", EnumToString(_Period));
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(ExtHandleATR != INVALID_HANDLE)
     {
      IndicatorRelease(ExtHandleATR);
      ExtHandleATR = INVALID_HANDLE;
     }
   Print("[*] TurtleTrader deinitialized. Reason: ", reason);
  }

//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtSymbol.RefreshRates();

   // Verify New Bar to avoid intra-bar overtrading on breakout evaluations
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   bool is_new_bar = (current_bar_time != ExtLastBarTime);

   // Determine Donchian Periods based on Mode
   int entry_len = (InpSystemMode == SYSTEM_1_SHORT_TERM) ? 20 : 55;
   int exit_len  = (InpSystemMode == SYSTEM_1_SHORT_TERM) ? 10 : 20;

   if(InpCustomEntryPeriod > 0)
      entry_len = InpCustomEntryPeriod;
   if(InpCustomExitPeriod > 0)
      exit_len = InpCustomExitPeriod;

   double entry_high = 0.0, entry_low = 0.0;
   double exit_high  = 0.0, exit_low  = 0.0;

   if(!GetDonchianChannel(entry_len, entry_high, entry_low))
      return;
   if(!GetDonchianChannel(exit_len, exit_high, exit_low))
      return;

   double N = GetCurrentN();
   if(N <= 0.0)
      return;

   // Count open positions and extract current exposure
   int    open_units      = 0;
   double total_volume    = 0.0;
   double latest_open_price = 0.0;
   ENUM_POSITION_TYPE pos_type = WRONG_VALUE;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(ExtPosition.SelectByIndex(i))
        {
         if(ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
           {
            open_units++;
            total_volume += ExtPosition.Volume();
            pos_type = ExtPosition.PositionType();
            if(latest_open_price == 0.0)
               latest_open_price = ExtPosition.PriceOpen();
           }
        }
     }

   double ask = ExtSymbol.Ask();
   double bid = ExtSymbol.Bid();

   //--- 1. Position Management & Exit Rules
   if(open_units > 0)
     {
      // Long Position Exit: Price crosses below Exit Donchian Low
      if(pos_type == POSITION_TYPE_BUY)
        {
         if(bid < exit_low)
           {
            Print("[*] Turtle Exit: Long position closed at ", bid, " (Below ", exit_len, "-day Low ", exit_low, ")");
            for(int i = PositionsTotal() - 1; i >= 0; i--)
              {
               if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
                  ExtTrade.PositionClose(ExtPosition.Ticket());
              }
            return;
           }

         // Pyramiding: Add Unit if price advances by 0.5N from last unit
         if(open_units < InpMaxUnits && ask >= latest_open_price + (InpPyramidStepN * N))
           {
            double unit_lots = CalculateUnitSize(N);
            double hard_sl   = NormalizeDouble(ask - (InpStopLossN * N), _Digits);
            if(ExtTrade.Buy(unit_lots, _Symbol, ask, hard_sl, 0.0, InpTradeComment + "_Pyramid"))
              {
               Print("[+] Pyramided Long Unit added: ", unit_lots, " at ", ask, " SL: ", hard_sl);
               // Move stops of all open units to the new unified Stop Loss
               for(int i = PositionsTotal() - 1; i >= 0; i--)
                 {
                  if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
                     ExtTrade.PositionModify(ExtPosition.Ticket(), hard_sl, ExtPosition.TakeProfit());
                 }
              }
           }
        }
      // Short Position Exit: Price crosses above Exit Donchian High
      else if(pos_type == POSITION_TYPE_SELL)
        {
         if(ask > exit_high)
           {
            Print("[*] Turtle Exit: Short position closed at ", ask, " (Above ", exit_len, "-day High ", exit_high, ")");
            for(int i = PositionsTotal() - 1; i >= 0; i--)
              {
               if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
                  ExtTrade.PositionClose(ExtPosition.Ticket());
              }
            return;
           }

         // Pyramiding: Add Unit if price declines by 0.5N from last unit
         if(open_units < InpMaxUnits && bid <= latest_open_price - (InpPyramidStepN * N))
           {
            double unit_lots = CalculateUnitSize(N);
            double hard_sl   = NormalizeDouble(bid + (InpStopLossN * N), _Digits);
            if(ExtTrade.Sell(unit_lots, _Symbol, bid, hard_sl, 0.0, InpTradeComment + "_Pyramid"))
              {
               Print("[+] Pyramided Short Unit added: ", unit_lots, " at ", bid, " SL: ", hard_sl);
               // Move stops of all open units to the new unified Stop Loss
               for(int i = PositionsTotal() - 1; i >= 0; i--)
                 {
                  if(ExtPosition.SelectByIndex(i) && ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
                     ExtTrade.PositionModify(ExtPosition.Ticket(), hard_sl, ExtPosition.TakeProfit());
                 }
              }
           }
        }
      return;
     }

   //--- 2. Fresh Entry Signals (Evaluated strictly on New Bar Open)
   if(!is_new_bar)
      return;
   ExtLastBarTime = current_bar_time;

   // Long Breakout: Close of previous bar broke above Donchian High
   double prev_close = iClose(_Symbol, _Period, 1);
   if(prev_close > entry_high)
     {
      double unit_lots = CalculateUnitSize(N);
      double hard_sl   = NormalizeDouble(ask - (InpStopLossN * N), _Digits);

      if(ExtTrade.Buy(unit_lots, _Symbol, ask, hard_sl, 0.0, InpTradeComment + "_Initial"))
         Print("[+] Turtle Initial Long Entry: ", unit_lots, " lots at ", ask, " Hard SL: ", hard_sl, " (Breakout of ", entry_len, "-period High: ", entry_high, ")");
      else
         Print("[-] Long order failed: ", ExtTrade.ResultRetcodeDescription());
     }
   // Short Breakout: Close of previous bar broke below Donchian Low
   else if(prev_close < entry_low)
     {
      double unit_lots = CalculateUnitSize(N);
      double hard_sl   = NormalizeDouble(bid + (InpStopLossN * N), _Digits);

      if(ExtTrade.Sell(unit_lots, _Symbol, bid, hard_sl, 0.0, InpTradeComment + "_Initial"))
         Print("[+] Turtle Initial Short Entry: ", unit_lots, " lots at ", bid, " Hard SL: ", hard_sl, " (Breakout of ", entry_len, "-period Low: ", entry_low, ")");
      else
         Print("[-] Short order failed: ", ExtTrade.ResultRetcodeDescription());
     }
  }
//+------------------------------------------------------------------+
