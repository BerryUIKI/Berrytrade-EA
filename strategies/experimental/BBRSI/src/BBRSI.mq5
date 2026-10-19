//+------------------------------------------------------------------+
//|                                                        BBRSI.mq5 |
//|                                          Copyright 2023, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2023, Geraked"
#property link        "https://github.com/geraked"
#property version     "1.8"
#property description "A strategy using Bollinger Bands and RSI"
#property description "XAUUSD-5M  2021.02.26 - 2023.09.15"

#include <EAUtils.mqh>

input group "Indicator Parameters"
input int BBLen = 500; // BB Period
input double BBDev = 2; // BB Deviations
input int RSILen = 7; // RSI Period

input group "General"
input double TPCoef = 1; // TP Coefficient
input double SLCoef = 0.9; // SL Coefficient
input int SLDev = 0; // SL Deviation (Points)
input bool CloseOrders = false; // Check For Closing Conditions
input bool CloseOnProfit = true; // Close Only On Profit
input bool Reverse = false; // Reverse Signal

input group "Risk Management"
input double Risk = 0.5; // Risk
input ENUM_RISK RiskMode = RISK_DEFAULT; // Risk Mode
input bool IgnoreSL = false; // Ignore SL
input bool IgnoreTP = false; // Ignore TP
input bool Trail = true; // Trailing Stop
input double TrailingStopLevel = 50; // Trailing Stop Level (%)
input double EquityDrawdownLimit = 10; // Peak Account Equity Drawdown Halt (%) (0: Disable)

input group "Strategy: Grid"
input bool Grid = false; // Grid Enable
input double GridVolMult = 1.1; // Grid Volume Multiplier
input double GridTrailingStopLevel = 0; // Grid Trailing Stop Level (%) (0: Disable)
input int GridMaxLvl = 20; // Grid Max Levels

input group "News Filter"
input bool News = false; // News Enable
input ENUM_NEWS_IMPORTANCE NewsImportance = NEWS_IMPORTANCE_MEDIUM; // News Importance
input int NewsMinsBefore = 60; // News Minutes Before
input int NewsMinsAfter = 60; // News Minutes After
input int NewsStartYear = 0; // News Start Year to Fetch for Backtesting (0: Disable)

input group "Open Position Limit"
input bool OpenNewPos = true; // Allow Opening New Position
input bool MultipleOpenPos = false; // Allow Having Multiple Open Positions
input double MarginLimit = 300; // Margin Limit (%) (0: Disable)
input int SpreadLimit = -1; // Spread Limit (Points) (-1: Disable)

input group "Auxiliary"
input int Slippage = 30; // Slippage (Points)
input int TimerInterval = 30; // Timer Interval (Seconds)
input ulong MagicNumber = 1000; // Magic Number
input ENUM_FILLING Filling = FILLING_DEFAULT; // Order Filling

GerEA ea;
datetime lastCandle;
datetime tc;
double peakEquity;
bool tradingHalted;

#define BuffSize 3
#define RSIMiddle 50
#define RSIUpper 70
#define RSILower 30

int BB_handle = INVALID_HANDLE, RSI_handle = INVALID_HANDLE;
double BB_U[], BB_L[], BB_M[], RSI[];
MqlRates signalBars[];

// A triggered halt lasts until this EA instance is reinitialized. Failed closes
// are retried on later ticks/timer events; new entries remain disabled meanwhile.
bool CheckEquityProtection() {
    if (EquityDrawdownLimit == 0) return true;
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    if (!MathIsValidNumber(equity)) return false;
    peakEquity = MathMax(peakEquity, equity);
    if (peakEquity <= 0) return false;
    double drawdown = (peakEquity - equity) / peakEquity;
    if (!tradingHalted && drawdown >= EquityDrawdownLimit * 0.01) {
        tradingHalted = true;
        PrintFormat("BBRSI equity halt: peak=%.2f equity=%.2f drawdown=%.2f%% limit=%.2f%%",
                    peakEquity, equity, drawdown * 100, EquityDrawdownLimit);
    }
    if (!tradingHalted) return true;
    ea.BuyClose(_Symbol);
    ea.SellClose(_Symbol);
    return false;
}

bool CanOpenNewPositions() {
    if (!OpenNewPos || tradingHalted) return false;
    if (SpreadLimit != -1 && Spread() > SpreadLimit) return false;
    if (MarginLimit && PositionsTotal() > 0 &&
        AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < MarginLimit) return false;
    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BuySignal() {
    bool c = RSI[2] < RSILower && signalBars[2].close < BB_L[2] && RSI[1] > RSILower && signalBars[1].close > BB_L[1] && RSI[1] < RSIMiddle && signalBars[1].close < BB_M[1];
    if (!c) return false;

    double in = Ask();
    double sl = !SLCoef ? in - SLDev * _Point : BB_L[1] - SLCoef * (BB_M[1] - BB_L[1]) - SLDev * _Point;
    double tp = in + TPCoef * MathAbs(in - sl);
    return ea.BuyOpen(in, sl, tp, IgnoreSL, IgnoreTP);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SellSignal() {
    bool c = RSI[2] > RSIUpper && signalBars[2].close > BB_U[2] && RSI[1] < RSIUpper && signalBars[1].close < BB_U[1] && RSI[1] > RSIMiddle && signalBars[1].close > BB_M[1];
    if (!c) return false;

    double in = Bid();
    double sl = !SLCoef ? in + SLDev * _Point : BB_U[1] + SLCoef * (BB_U[1] - BB_M[1]) + SLDev * _Point;
    double tp = in - TPCoef * MathAbs(in - sl);
    return ea.SellOpen(in, sl, tp, IgnoreSL, IgnoreTP);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckClose() {
    if (CloseOnProfit) {
        double p = getProfit(ea.GetMagic()) - calcCost(ea.GetMagic());
        if (p < 0) return;
    }

    if (signalBars[2].close <= BB_M[2] && signalBars[1].close > BB_M[1])
        ea.BuyClose();
    if (signalBars[2].close >= BB_M[2] && signalBars[1].close < BB_M[1])
        ea.SellClose();
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    if (BBLen < 2 || BBDev <= 0 || RSILen < 1 || TimerInterval < 1 ||
        Risk <= 0 || TPCoef < 0 || SLCoef < 0 || SLDev < 0 ||
        TrailingStopLevel < 0 || TrailingStopLevel > 100 ||
        GridTrailingStopLevel < 0 || GridTrailingStopLevel > 100 ||
        EquityDrawdownLimit < 0 || EquityDrawdownLimit >= 100 ||
        (Grid && (GridVolMult <= 0 || GridMaxLvl < 1)) ||
        SpreadLimit < -1 || MarginLimit < 0 || Slippage < 0 ||
        NewsMinsBefore < 0 || NewsMinsAfter < 0) {
        Print("Invalid BBRSI input parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    if (Grid && AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
        Print("BBRSI grid requires a hedging account");
        return INIT_PARAMETERS_INCORRECT;
    }

    tradingHalted = false;
    peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    lastCandle = 0;
    tc = 0;
    if (EquityDrawdownLimit > 0 && (!MathIsValidNumber(peakEquity) || peakEquity <= 0)) {
        Print("BBRSI equity protection requires positive starting equity");
        return INIT_FAILED;
    }

    ea.Init();
    ea.SetMagic(MagicNumber);
    ea.risk = Risk * 0.01;
    ea.reverse = Reverse;
    ea.trailingStopLevel = TrailingStopLevel * 0.01;
    ea.grid = Grid;
    ea.gridVolMult = GridVolMult;
    ea.gridTrailingStopLevel = GridTrailingStopLevel * 0.01;
    ea.gridMaxLvl = GridMaxLvl;
    ea.equityDrawdownLimit = EquityDrawdownLimit * 0.01;
    ea.slippage = Slippage;
    ea.news = News;
    ea.newsImportance = NewsImportance;
    ea.newsMinsBefore = NewsMinsBefore;
    ea.newsMinsAfter = NewsMinsAfter;
    ea.filling = Filling;
    ea.riskMode = RiskMode;

    if (RiskMode == RISK_FIXED_VOL || RiskMode == RISK_MIN_AMOUNT) ea.risk = Risk;
    if (News) fetchCalendarFromYear(NewsStartYear);

    BB_handle = iBands(NULL, 0, BBLen, 0, BBDev, PRICE_CLOSE);
    RSI_handle = iRSI(NULL, 0, RSILen, PRICE_CLOSE);

    if (BB_handle == INVALID_HANDLE || RSI_handle == INVALID_HANDLE) {
        Print("Runtime error = ", GetLastError());
        return INIT_FAILED;
    }

    ArraySetAsSeries(BB_M, true);
    ArraySetAsSeries(BB_U, true);
    ArraySetAsSeries(BB_L, true);
    ArraySetAsSeries(RSI, true);
    ArraySetAsSeries(signalBars, true);

    if (!EventSetTimer(TimerInterval)) {
        Print("Cannot start BBRSI timer: ", GetLastError());
        return INIT_FAILED;
    }
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    if (BB_handle != INVALID_HANDLE) IndicatorRelease(BB_handle);
    if (RSI_handle != INVALID_HANDLE) IndicatorRelease(RSI_handle);
    BB_handle = INVALID_HANDLE;
    RSI_handle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    if (!CheckEquityProtection()) return;
    datetime oldTc = tc;
    tc = TimeCurrent();
    if (tc == oldTc) return;

    if (Trail) ea.CheckForTrail();
    if (Grid && CanOpenNewPositions()) ea.CheckForGrid();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (!CheckEquityProtection()) return;
    datetime currentCandle = iTime(_Symbol, _Period, 0);
    if (currentCandle == 0 || currentCandle == lastCandle) return;
    if (BarsCalculated(BB_handle) < BBLen + BuffSize ||
        BarsCalculated(RSI_handle) < RSILen + BuffSize) return;

    if (CopyRates(_Symbol, _Period, 0, BuffSize, signalBars) != BuffSize) return;
    if (CopyBuffer(BB_handle, 0, 0, BuffSize, BB_M) != BuffSize) return;
    if (CopyBuffer(BB_handle, 1, 0, BuffSize, BB_U) != BuffSize) return;
    if (CopyBuffer(BB_handle, 2, 0, BuffSize, BB_L) != BuffSize) return;
    if (CopyBuffer(RSI_handle, 0, 0, BuffSize, RSI) != BuffSize) return;

    // Retry on a later tick if history was unavailable or changed during copying.
    if (signalBars[0].time != currentCandle ||
        iTime(_Symbol, _Period, 0) != currentCandle) return;
    for (int i = 1; i < BuffSize; i++) {
        if (!MathIsValidNumber(BB_M[i]) || BB_M[i] == EMPTY_VALUE ||
            !MathIsValidNumber(BB_U[i]) || BB_U[i] == EMPTY_VALUE ||
            !MathIsValidNumber(BB_L[i]) || BB_L[i] == EMPTY_VALUE ||
            !MathIsValidNumber(RSI[i]) || RSI[i] == EMPTY_VALUE) return;
    }
    lastCandle = currentCandle;

    if (CloseOrders) CheckClose();

    if (!CanOpenNewPositions()) return;
    if ((Grid || !MultipleOpenPos) && ea.OPTotal() > 0) return;

    if (BuySignal()) return;
    SellSignal();
}

//+------------------------------------------------------------------+
