//+------------------------------------------------------------------+
//|                                                 HMMRegimeEA.mq5 |
//|        Copyright 2026, Berrytrade Quantitative Research, Singapore|
//|                                        https://www.berrytrade.org |
//|                                                                  |
//| Institutional Open-Source Algorithmic Ingestion Pipeline         |
//| Model: Hidden Markov Model (HMM) Gaussian Mixture Regime Filter  |
//| Standards: Zero DLLs, Dynamic Fractional Risk, Hard Stop-Loss     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Berrytrade Quantitative Research, Singapore"
#property link        "https://www.berrytrade.org"
#property version     "1.00"
#property description "HMMRegimeEA: Real-Time Hidden Markov Model Gaussian Mixture Regime-Switching Volatility Filter"
#property description "Executes disciplined trend-following trades exclusively during low-volatility persistent regimes with zero grid/martingale."

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input Parameters: HMM Core Architecture
input group "=== Hidden Markov Model Parameters ==="
input double   InpProbStayRegime1      = 0.95;      // Transition Prob: Stay in Regime 1 (Low-Vol Trend, p11)
input double   InpProbStayRegime2      = 0.90;      // Transition Prob: Stay in Regime 2 (High-Vol Turmoil, p22)
input double   InpSigmaRegime1         = 0.0035;    // Regime 1 Expected Return Volatility (sigma_1)
input double   InpSigmaRegime2         = 0.0120;    // Regime 2 Expected Return Volatility (sigma_2)
input double   InpRegimeConfidence     = 0.65;      // Minimum Posterior Probability to Confirm Trend Regime
input int      InpEMAFastPeriod        = 21;        // Directional Trend Filter Fast EMA Period
input int      InpEMASlowPeriod        = 55;        // Directional Trend Filter Slow EMA Period
input int      InpATRPeriod            = 14;        // ATR Volatility Normalization Period

//--- Input Parameters: Risk Management & Order Execution
input group "=== Risk & Money Management ==="
input double   InpRiskPercent          = 1.0;       // Capital-at-Risk per Trade (% of Equity)
input double   InpStopLossATRMult      = 2.0;       // Hard Stop Loss (ATR Multiplier)
input double   InpTakeProfitATRMult    = 3.5;       // Take Profit (ATR Multiplier)
input ulong    InpMagicNumber          = 106001;    // EA Magic Identifier
input ulong    InpSlippagePoints       = 20;        // Maximum Tolerable Execution Slippage (Points)
input bool     InpExitOnTurmoil        = true;      // Flatten Position upon High-Volatility Turmoil Detection
input bool     InpCloseFriday          = true;      // Flatten Positions Prior to Friday Weekend Close
input int      InpFridayCloseHour      = 21;        // Friday Forced Liquidation Hour (GMT)

//--- Global Variables & Objects
CTrade         g_trade;
CSymbolInfo    g_symbol;
CPositionInfo  g_position;

int            g_ema_fast_handle = INVALID_HANDLE;
int            g_ema_slow_handle = INVALID_HANDLE;
int            g_atr_handle      = INVALID_HANDLE;
datetime       g_last_bar_time   = 0;

//--- HMM State Variables
double         g_prob_regime1 = 0.5;   // Prior/Posterior Probability: State 1 (Low-Vol Trend)
double         g_prob_regime2 = 0.5;   // Prior/Posterior Probability: State 2 (High-Vol Turmoil)
bool           g_hmm_initialized = false;
double         g_last_price = 0.0;

#define M_PI 3.14159265358979323846

//+------------------------------------------------------------------+
//| Univariate Gaussian Probability Density Function                 |
//+------------------------------------------------------------------+
double GaussianDensity(double x, double mean_val, double sigma_val)
{
   if(sigma_val <= 0.0) sigma_val = 0.0001;
   double diff = x - mean_val;
   double exponent = -0.5 * (diff * diff) / (sigma_val * sigma_val);
   double denom = sigma_val * MathSqrt(2.0 * M_PI);
   return MathExp(exponent) / denom;
}

//+------------------------------------------------------------------+
//| Recursive Hamilton Forward Filter Update                         |
//+------------------------------------------------------------------+
void UpdateHamiltonFilter(double log_return)
{
   if(!g_hmm_initialized)
   {
      g_prob_regime1 = 0.5;
      g_prob_regime2 = 0.5;
      g_hmm_initialized = true;
      return;
   }
   
   // 1. Prediction Step: pi_{t|t-1} = P^T * pi_{t-1|t-1}
   // Transition matrix:
   // P = [[p11, 1-p11], [1-p22, p22]]
   double p11 = InpProbStayRegime1;
   double p12 = 1.0 - p11;
   double p22 = InpProbStayRegime2;
   double p21 = 1.0 - p22;
   
   double pred_regime1 = g_prob_regime1 * p11 + g_prob_regime2 * p21;
   double pred_regime2 = g_prob_regime1 * p12 + g_prob_regime2 * p22;
   
   // 2. Emission Densities: f(r_t | S_t = s)
   double f1 = GaussianDensity(log_return, 0.0, InpSigmaRegime1);
   double f2 = GaussianDensity(log_return, 0.0, InpSigmaRegime2);
   
   // 3. Bayesian Measurement Update (Posterior Filtering)
   double joint1 = pred_regime1 * f1;
   double joint2 = pred_regime2 * f2;
   double marginal_likelihood = joint1 + joint2;
   
   if(marginal_likelihood > 1e-12)
   {
      g_prob_regime1 = joint1 / marginal_likelihood;
      g_prob_regime2 = joint2 / marginal_likelihood;
   }
   else
   {
      // Numerical floor fallback
      g_prob_regime1 = pred_regime1;
      g_prob_regime2 = pred_regime2;
   }
   
   // Ensure probabilities strictly sum to 1.0
   double norm = g_prob_regime1 + g_prob_regime2;
   if(norm > 0.0)
   {
      g_prob_regime1 /= norm;
      g_prob_regime2 /= norm;
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_symbol.Name(_Symbol))
   {
      Print("[-] Failed to initialize symbol info for: ", _Symbol);
      return INIT_FAILED;
   }
   
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePoints);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   
   // Initialize Indicators
   g_ema_fast_handle = iMA(_Symbol, _Period, InpEMAFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_ema_slow_handle = iMA(_Symbol, _Period, InpEMASlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_atr_handle      = iATR(_Symbol, _Period, InpATRPeriod);
   
   if(g_ema_fast_handle == INVALID_HANDLE || g_ema_slow_handle == INVALID_HANDLE || g_atr_handle == INVALID_HANDLE)
   {
      Print("[-] Failed to create indicator handles. Check symbol and timeframe parameters.");
      return INIT_FAILED;
   }
   
   g_prob_regime1 = 0.5;
   g_prob_regime2 = 0.5;
   g_hmm_initialized = false;
   g_last_price = 0.0;
   
   Print("[+] HMMRegimeEA initialized successfully on ", _Symbol, " with Magic: ", InpMagicNumber);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_ema_fast_handle != INVALID_HANDLE) IndicatorRelease(g_ema_fast_handle);
   if(g_ema_slow_handle != INVALID_HANDLE) IndicatorRelease(g_ema_slow_handle);
   if(g_atr_handle      != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
   Print("[*] HMMRegimeEA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size based on Account Risk and Stop-Loss Distance  |
//+------------------------------------------------------------------+
double CalculateRiskLotSize(double sl_distance_points)
{
   if(sl_distance_points <= 0.0) return g_symbol.LotsMin();
   
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = equity * (InpRiskPercent / 100.0);
   
   double tick_value = g_symbol.TickValue();
   double tick_size  = g_symbol.TickSize();
   double point      = g_symbol.Point();
   
   if(tick_size <= 0.0 || tick_value <= 0.0 || point <= 0.0)
   {
      return g_symbol.LotsMin();
   }
   
   double loss_per_lot = (sl_distance_points * point / tick_size) * tick_value;
   if(loss_per_lot <= 0.0) return g_symbol.LotsMin();
   
   double calculated_lot = risk_amount / loss_per_lot;
   
   // Bound by broker constraints
   double lot_step = g_symbol.LotsStep();
   double min_lot  = g_symbol.LotsMin();
   double max_lot  = g_symbol.LotsMax();
   
   calculated_lot = MathFloor(calculated_lot / lot_step) * lot_step;
   if(calculated_lot < min_lot) calculated_lot = min_lot;
   if(calculated_lot > max_lot) calculated_lot = max_lot;
   
   return calculated_lot;
}

//+------------------------------------------------------------------+
//| Check Existing Open Position for This Strategy                   |
//+------------------------------------------------------------------+
bool HasOpenPosition(long &out_type, ulong &out_ticket)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Symbol() == _Symbol && g_position.Magic() == InpMagicNumber)
         {
            out_type = g_position.PositionType();
            out_ticket = g_position.Ticket();
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Close Strategy Open Positions                                    |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.Symbol() == _Symbol && g_position.Magic() == InpMagicNumber)
         {
            Print("[*] Closing position #", g_position.Ticket(), " Reason: ", reason);
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
   // Execute core logic on bar completion
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   if(current_bar_time == g_last_bar_time) return;
   
   g_symbol.RefreshRates();
   
   // Friday close enforcement
   if(InpCloseFriday)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour)
      {
         CloseAllPositions("Friday Weekend Risk Flattening");
         g_last_bar_time = current_bar_time;
         return;
      }
   }
   
   // Fetch indicator values from closed bar [1]
   double ema_fast[2], ema_slow[2], atr[2];
   if(CopyBuffer(g_ema_fast_handle, 0, 1, 2, ema_fast) < 2 ||
      CopyBuffer(g_ema_slow_handle, 0, 1, 2, ema_slow) < 2 ||
      CopyBuffer(g_atr_handle, 0, 1, 2, atr) < 2)
   {
      return;
   }
   
   double close1 = iClose(_Symbol, _Period, 1);
   double close2 = iClose(_Symbol, _Period, 2);
   
   // Calculate log-return r_t = ln(Close_1 / Close_2)
   if(close2 > 0.0 && close1 > 0.0)
   {
      double log_ret = MathLog(close1 / close2);
      UpdateHamiltonFilter(log_ret);
   }
   
   double current_atr = atr[1];
   if(current_atr <= 0.0) current_atr = g_symbol.Point() * 100;
   
   long pos_type = -1;
   ulong pos_ticket = 0;
   bool has_pos = HasOpenPosition(pos_type, pos_ticket);
   
   // Defensive Exit: High-Volatility Turmoil detected
   if(has_pos && InpExitOnTurmoil)
   {
      if(g_prob_regime2 > InpRegimeConfidence)
      {
         CloseAllPositions("Turbulent Regime Detected (P(Regime 2) = " + DoubleToString(g_prob_regime2, 3) + ")");
         has_pos = false;
      }
   }
   
   // Check Entry Conditions: Only allow entry when market is in Regime 1 (Low-Vol Directional Trend)
   bool is_trend_regime = (g_prob_regime1 >= InpRegimeConfidence);
   
   if(!has_pos && is_trend_regime)
   {
      double ask = g_symbol.Ask();
      double bid = g_symbol.Bid();
      double point = g_symbol.Point();
      
      double sl_distance_points = (current_atr * InpStopLossATRMult) / point;
      double tp_distance_points = (current_atr * InpTakeProfitATRMult) / point;
      double lot = CalculateRiskLotSize(sl_distance_points);
      
      // Long Signal: EMA Fast > EMA Slow, Price > Fast EMA, and Regime 1 confirmed
      if(ema_fast[1] > ema_slow[1] && close1 > ema_fast[1])
      {
         double sl = NormalizeDouble(ask - sl_distance_points * point, (int)g_symbol.Digits());
         double tp = NormalizeDouble(ask + tp_distance_points * point, (int)g_symbol.Digits());
         
         PrintFormat("[+] HMM Long Entry: Lot=%.2f, Ask=%.5f, SL=%.5f, TP=%.5f, P(Trend)=%.3f",
                     lot, ask, sl, tp, g_prob_regime1);
         g_trade.Buy(lot, _Symbol, ask, sl, tp, "HMMRegimeEA: Trend Long");
      }
      // Short Signal: EMA Fast < EMA Slow, Price < Fast EMA, and Regime 1 confirmed
      else if(ema_fast[1] < ema_slow[1] && close1 < ema_fast[1])
      {
         double sl = NormalizeDouble(bid + sl_distance_points * point, (int)g_symbol.Digits());
         double tp = NormalizeDouble(bid - tp_distance_points * point, (int)g_symbol.Digits());
         
         PrintFormat("[+] HMM Short Entry: Lot=%.2f, Bid=%.5f, SL=%.5f, TP=%.5f, P(Trend)=%.3f",
                     lot, bid, sl, tp, g_prob_regime1);
         g_trade.Sell(lot, _Symbol, bid, sl, tp, "HMMRegimeEA: Trend Short");
      }
   }
   
   g_last_bar_time = current_bar_time;
}
//+------------------------------------------------------------------+
