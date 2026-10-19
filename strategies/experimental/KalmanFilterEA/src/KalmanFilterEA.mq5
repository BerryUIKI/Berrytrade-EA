//+------------------------------------------------------------------+
//|                                               KalmanFilterEA.mq5 |
//|        Copyright 2026, Berrytrade Quantitative Research, Singapore|
//|                                        https://www.berrytrade.org |
//|                                                                  |
//| Institutional Open-Source Algorithmic Ingestion Pipeline         |
//| Model: State-Space Adaptive Kalman Filter & Real-Time Drift EA   |
//| Standards: Zero DLLs, Dynamic Fractional Risk, Hard Stop-Loss     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Berrytrade Quantitative Research, Singapore"
#property link        "https://www.berrytrade.org"
#property version     "1.00"
#property description "KalmanFilterEA: Continuous 2D Kinematic State-Space Adaptive Price Drift Estimation"
#property description "Executes disciplined momentum trend entries based on real-time velocity drift with zero grid/martingale."

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input Parameters: Strategy Core
input group "=== Kalman Filter Parameters ==="
input double   InpProcessNoiseQ        = 0.0001;    // Process Noise Covariance (Q)
input double   InpMeasurementNoiseR    = 0.01;      // Measurement Noise Covariance (R)
input double   InpVelocityThreshold    = 0.25;      // Drift Velocity Sensitivity Factor (ATR units)
input int      InpATRPeriod            = 14;        // ATR Volatility Normalization Period

//--- Input Parameters: Risk Management & Order Execution
input group "=== Risk & Money Management ==="
input double   InpRiskPercent          = 1.0;       // Capital-at-Risk per Trade (% of Equity)
input double   InpStopLossATRMult      = 2.0;       // Hard Stop Loss (ATR Multiplier)
input double   InpTakeProfitATRMult    = 3.5;       // Take Profit (ATR Multiplier)
input ulong    InpMagicNumber          = 105001;    // EA Magic Identifier
input ulong    InpSlippagePoints       = 20;        // Maximum Tolerable Execution Slippage (Points)
input bool     InpCloseOnOppositeDrift = true;      // Close Active Position on Filter Drift Reversal
input bool     InpCloseFriday          = true;      // Flatten Positions Prior to Friday Weekend Close
input int      InpFridayCloseHour      = 21;        // Friday Forced Liquidation Hour (GMT)

//--- Global Variables & Objects
CTrade         g_trade;
CSymbolInfo    g_symbol;
CPositionInfo  g_position;

int            g_atr_handle = INVALID_HANDLE;
datetime       g_last_bar_time = 0;

//--- 2D Kalman Filter State Variables (State vector: [price, velocity]^T)
double         g_state_x[2];       // [0]: estimated price (p), [1]: estimated drift velocity (v)
double         g_cov_p[2][2];      // 2x2 State Estimation Covariance Matrix
bool           g_filter_initialized = false;

//+------------------------------------------------------------------+
//| Initialize 2D Kinematic Kalman Filter                            |
//+------------------------------------------------------------------+
void InitializeKalmanFilter(double initial_price)
{
   g_state_x[0] = initial_price;
   g_state_x[1] = 0.0; // initial velocity assumption
   
   // Initial error covariance P
   g_cov_p[0][0] = 1.0;
   g_cov_p[0][1] = 0.0;
   g_cov_p[1][0] = 0.0;
   g_cov_p[1][1] = 1.0;
   
   g_filter_initialized = true;
}

//+------------------------------------------------------------------+
//| Update 2D Kalman Filter with New Price Observation               |
//+------------------------------------------------------------------+
void UpdateKalmanFilter(double z_price, double dt)
{
   if(!g_filter_initialized)
   {
      InitializeKalmanFilter(z_price);
      return;
   }
   
   // 1. Time Update (Predict step)
   // State transition matrix F = [[1, dt], [0, 1]]
   // x_pred = F * x
   double x_pred[2];
   x_pred[0] = g_state_x[0] + dt * g_state_x[1];
   x_pred[1] = g_state_x[1];
   
   // Process noise matrix Q (Kinematic continuous white noise acceleration)
   double dt2 = dt * dt;
   double dt3 = dt2 * dt;
   double dt4 = dt3 * dt;
   double q = InpProcessNoiseQ;
   
   double q_mat[2][2];
   q_mat[0][0] = 0.25 * dt4 * q;
   q_mat[0][1] = 0.5 * dt3 * q;
   q_mat[1][0] = 0.5 * dt3 * q;
   q_mat[1][1] = dt2 * q;
   
   // P_pred = F * P * F^T + Q
   double p_pred[2][2];
   p_pred[0][0] = g_cov_p[0][0] + dt * (g_cov_p[1][0] + g_cov_p[0][1]) + dt2 * g_cov_p[1][1] + q_mat[0][0];
   p_pred[0][1] = g_cov_p[0][1] + dt * g_cov_p[1][1] + q_mat[0][1];
   p_pred[1][0] = g_cov_p[1][0] + dt * g_cov_p[1][1] + q_mat[1][0];
   p_pred[1][1] = g_cov_p[1][1] + q_mat[1][1];
   
   // 2. Measurement Update (Correction step)
   // Measurement matrix H = [1, 0]
   // Innovation: y = z - H * x_pred = z - x_pred[0]
   double y_residual = z_price - x_pred[0];
   
   // Innovation covariance: S = H * P_pred * H^T + R = P_pred[0][0] + R
   double s_cov = p_pred[0][0] + InpMeasurementNoiseR;
   if(s_cov <= 0.0) s_cov = 1e-9;
   
   // Kalman Gain: K = P_pred * H^T / S
   double k_gain[2];
   k_gain[0] = p_pred[0][0] / s_cov;
   k_gain[1] = p_pred[1][0] / s_cov;
   
   // Updated State: x = x_pred + K * y
   g_state_x[0] = x_pred[0] + k_gain[0] * y_residual;
   g_state_x[1] = x_pred[1] + k_gain[1] * y_residual;
   
   // Updated Covariance: P = (I - K * H) * P_pred
   g_cov_p[0][0] = (1.0 - k_gain[0]) * p_pred[0][0];
   g_cov_p[0][1] = (1.0 - k_gain[0]) * p_pred[0][1];
   g_cov_p[1][0] = p_pred[1][0] - k_gain[1] * p_pred[0][0];
   g_cov_p[1][1] = p_pred[1][1] - k_gain[1] * p_pred[0][1];
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Fractional Lot Sizing with Broker Constraints  |
//+------------------------------------------------------------------+
double CalculateDynamicLots(double sl_distance_points)
{
   if(sl_distance_points <= 0.0)
      return g_symbol.LotsMin();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_capital = equity * (InpRiskPercent / 100.0);

   double tick_value = g_symbol.TickValue();
   double tick_size  = g_symbol.TickSize();
   double point      = g_symbol.Point();

   if(tick_size <= 0.0 || point <= 0.0 || tick_value <= 0.0)
      return g_symbol.LotsMin();

   double points_per_tick = tick_size / point;
   double risk_per_lot = (sl_distance_points / points_per_tick) * tick_value;

   if(risk_per_lot <= 0.0)
      return g_symbol.LotsMin();

   double raw_lots = risk_capital / risk_per_lot;

   // Normalize lot size according to broker constraints
   double lot_step = g_symbol.LotsStep();
   double min_lot  = g_symbol.LotsMin();
   double max_lot  = g_symbol.LotsMax();

   if(lot_step <= 0.0) lot_step = 0.01;
   double normalized_lots = MathFloor(raw_lots / lot_step) * lot_step;

   if(normalized_lots < min_lot) normalized_lots = min_lot;
   if(normalized_lots > max_lot) normalized_lots = max_lot;

   return normalized_lots;
}

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbol.Name(_Symbol))
   {
      Print("[!] Error initializing symbol: ", _Symbol);
      return INIT_FAILED;
   }
   g_symbol.Refresh();

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePoints);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);

   // Initialize ATR volatility indicator handle
   g_atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   if(g_atr_handle == INVALID_HANDLE)
   {
      Print("[!] Failed to create iATR indicator handle.");
      return INIT_FAILED;
   }

   // Seed the Kalman Filter using historical close prices
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 100, rates);
   if(copied > 0)
   {
      InitializeKalmanFilter(rates[copied - 1].close);
      for(int i = copied - 2; i >= 0; i--)
      {
         UpdateKalmanFilter(rates[i].close, 1.0);
      }
      Print("[+] KalmanFilterEA initialized and calibrated across ", copied, " historical bars.");
   }
   else
   {
      g_filter_initialized = false;
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_atr_handle != INVALID_HANDLE)
   {
      IndicatorRelease(g_atr_handle);
      g_atr_handle = INVALID_HANDLE;
   }
   Print("[-] KalmanFilterEA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check bar status to execute primarily on bar completion (H1 regime)
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   if(current_bar_time == g_last_bar_time)
      return;

   if(!g_symbol.RefreshRates())
      return;

   // 1. Friday close check
   if(InpCloseFriday)
   {
      MqlDateTime dt;
      TimeCurrent(dt);
      if(dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour)
      {
         // Close all active positions
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if(g_position.SelectByIndex(i))
            {
               if(g_position.Magic() == InpMagicNumber && g_position.Symbol() == _Symbol)
               {
                  g_trade.PositionClose(g_position.Ticket());
               }
            }
         }
         g_last_bar_time = current_bar_time;
         return;
      }
   }

   // 2. Read latest completed bar data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2)
      return;

   double completed_close = rates[0].close;

   // Read ATR value
   double atr_val[];
   ArraySetAsSeries(atr_val, true);
   if(CopyBuffer(g_atr_handle, 0, 1, 1, atr_val) < 1)
      return;

   double current_atr = atr_val[0];
   if(current_atr <= 0.0)
      return;

   // 3. Update State-Space Kalman Filter with latest completed close
   UpdateKalmanFilter(completed_close, 1.0);

   double est_price    = g_state_x[0];
   double est_velocity = g_state_x[1];

   // Drift threshold scaled by volatility (ATR)
   double drift_threshold = InpVelocityThreshold * current_atr;

   // Check current active exposure
   bool has_long = false;
   bool has_short = false;
   ulong pos_ticket = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Magic() == InpMagicNumber && g_position.Symbol() == _Symbol)
         {
            pos_ticket = g_position.Ticket();
            if(g_position.PositionType() == POSITION_TYPE_BUY)
               has_long = true;
            else if(g_position.PositionType() == POSITION_TYPE_SELL)
               has_short = true;
         }
      }
   }

   // 4. Reverse drift exit logic
   if(InpCloseOnOppositeDrift)
   {
      if(has_long && est_velocity < -drift_threshold)
      {
         g_trade.PositionClose(pos_ticket);
         has_long = false;
      }
      else if(has_short && est_velocity > drift_threshold)
      {
         g_trade.PositionClose(pos_ticket);
         has_short = false;
      }
   }

   // 5. Entry Signal Generation
   double point = g_symbol.Point();
   double sl_distance_points = (InpStopLossATRMult * current_atr) / point;
   double tp_distance_points = (InpTakeProfitATRMult * current_atr) / point;
   double lot_size = CalculateDynamicLots(sl_distance_points);

   // Long Signal: Positive velocity drift exceeds threshold AND close is above estimated fair price
   if(!has_long && !has_short && est_velocity > drift_threshold && completed_close > est_price)
   {
      double ask = g_symbol.Ask();
      double sl = ask - (InpStopLossATRMult * current_atr);
      double tp = ask + (InpTakeProfitATRMult * current_atr);

      sl = g_symbol.NormalizePrice(sl);
      tp = g_symbol.NormalizePrice(tp);

      g_trade.Buy(lot_size, _Symbol, ask, sl, tp, "KalmanFilter Long Drift");
   }
   // Short Signal: Negative velocity drift exceeds threshold AND close is below estimated fair price
   else if(!has_long && !has_short && est_velocity < -drift_threshold && completed_close < est_price)
   {
      double bid = g_symbol.Bid();
      double sl = bid + (InpStopLossATRMult * current_atr);
      double tp = bid - (InpTakeProfitATRMult * current_atr);

      sl = g_symbol.NormalizePrice(sl);
      tp = g_symbol.NormalizePrice(tp);

      g_trade.Sell(lot_size, _Symbol, bid, sl, tp, "KalmanFilter Short Drift");
   }

   g_last_bar_time = current_bar_time;
}
//+------------------------------------------------------------------+
