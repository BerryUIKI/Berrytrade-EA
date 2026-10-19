//+------------------------------------------------------------------+
//|                                                    TradeRisk.mqh |
//|                                  Copyright 2026, Berrytrade Community |
//|                                              https://berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Community"
#property link      "https://github.com/BerryUIKI/Berrytrade-EA"
#property version   "1.00"

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| Class CTradeRiskManager: Standardized Broker & Account Risk Rules|
//+------------------------------------------------------------------+
class CTradeRiskManager
{
public:
   CTradeRiskManager() {}
   ~CTradeRiskManager() {}

   //+---------------------------------------------------------------+
   //| Calculate Lot Size based on fixed percent equity risk         |
   //+---------------------------------------------------------------+
   static double CalculateLotSize(const string symbol, const double riskPercent, const double stopLossPoints)
   {
      if(stopLossPoints <= 0.0 || riskPercent <= 0.0)
         return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

      double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskAmount = accountEquity * (riskPercent / 100.0);

      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      if(tickSize <= 0.0 || point <= 0.0 || tickValue <= 0.0)
         return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

      double lossPerLot = (stopLossPoints * point / tickSize) * tickValue;
      if(lossPerLot <= 0.0)
         return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

      double rawLot = riskAmount / lossPerLot;
      return NormalizeVolume(symbol, rawLot);
   }

   //+---------------------------------------------------------------+
   //| Normalize Lot Size to broker volume step, min, and max limits |
   //+---------------------------------------------------------------+
   static double NormalizeVolume(const string symbol, double volume)
   {
      double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double minVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

      if(step <= 0.0)
         step = 0.01;

      volume = MathFloor(volume / step) * step;

      if(volume < minVol)
         volume = minVol;
      if(volume > maxVol)
         volume = maxVol;

      int digits = (step < 0.1) ? 2 : ((step < 1.0) ? 1 : 0);
      return NormalizeDouble(volume, digits);
   }

   //+---------------------------------------------------------------+
   //| Check if Stop-Loss complies with broker stops level distance  |
   //+---------------------------------------------------------------+
   static bool CheckStopLossValid(const string symbol, const ENUM_ORDER_TYPE orderType, const double openPrice, const double stopLoss)
   {
      if(stopLoss <= 0.0)
         return false; // Hard stop loss is strictly required

      int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double minDistance = stopsLevel * point;

      if(orderType == ORDER_TYPE_BUY)
      {
         if(stopLoss >= openPrice - minDistance)
            return false;
      }
      else if(orderType == ORDER_TYPE_SELL)
      {
         if(stopLoss <= openPrice + minDistance)
            return false;
      }

      return true;
   }
};
