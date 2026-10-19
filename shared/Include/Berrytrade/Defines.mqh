//+------------------------------------------------------------------+
//|                                                      Defines.mqh |
//|                                  Copyright 2026, Berrytrade Community |
//|                                              https://berrytrade.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Berrytrade Community"
#property link      "https://github.com/BerryUIKI/Berrytrade-EA"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Strategy Risk Tiers & Classifications                            |
//+------------------------------------------------------------------+
enum ENUM_STRATEGY_TIER
{
   TIER_EXPERIMENTAL = 0, // Community / Incubator Strategy
   TIER_VERIFIED     = 1  // Benchmarked / Production Strategy
};

enum ENUM_STRATEGY_CATEGORY
{
   CATEGORY_TREND_FOLLOWING = 0, // Trend following / momentum
   CATEGORY_MEAN_REVERSION  = 1, // Range / RSI / Bollinger mean reversion
   CATEGORY_BREAKOUT        = 2, // Volatility / support-resistance breakout
   CATEGORY_SCALPING        = 3, // Low-timeframe M1/M5 scalping
   CATEGORY_GRID            = 4, // Grid trading (non-multiplier)
   CATEGORY_MARTINGALE      = 5, // Martingale (Extreme Risk)
   CATEGORY_PORTFOLIO       = 6  // Multi-asset / Basket strategy
};

enum ENUM_RISK_RATING
{
   RISK_LOW      = 0, // Hard stop loss, nominal drawdown < 10%
   RISK_MEDIUM   = 1, // Standard discretionary / swing model (< 20% DD)
   RISK_HIGH     = 2, // High frequency or tight stop / latency sensitive
   RISK_EXTREME  = 3  // Martingale / Uncapped Grid (High probability of liquidation)
};

//+------------------------------------------------------------------+
//| Standard Execution Errors & Status Codes                        |
//+------------------------------------------------------------------+
enum ENUM_EXECUTION_STATUS
{
   STATUS_OK                 = 0, // Ready to execute
   STATUS_ERR_INVALID_SL     = 1, // Stop Loss violates broker min distance
   STATUS_ERR_INVALID_LOT    = 2, // Lot size below min or invalid step
   STATUS_ERR_SPREAD_TOO_HIGH= 3, // Current spread exceeds max allowed threshold
   STATUS_ERR_OVERNIGHT_BLOCKED = 4 // Trade disallowed due to overnight restriction
};
