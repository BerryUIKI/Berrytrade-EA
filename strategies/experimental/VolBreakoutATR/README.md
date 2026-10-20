# 📊 VolBreakoutATR: Extreme-Value Volatility Breakout Strategy

> **Strategy Class**: Volatility Breakout / Momentum  
> **Target Asset**: `EURUSD`, `GBPUSD`, `USDJPY`  
> **Recommended Timeframe**: `H1`  
> **Execution Profile**: Low Latency (120ms benchmark), Floating Spread, \$7/lot round-turn commission  
> **Risk Architecture**: Zero Grid, Zero Martingale, Dynamic Fractional Equity Sizing (1.0%), Hard ATR Stop-Loss  

---

## 1. Strategy Overview

**VolBreakoutATR** captures high-momentum regime transitions using continuous-time extreme-value volatility estimators:
1. **Garman-Klass Volatility Estimation**: Replaces discrete closing-price variance with intraday extreme-value estimators incorporating high, low, open, and close prices, providing up to 8x efficiency over classical sample variance.
2. **Volatility Contraction (Squeeze)**: Identifies market quiet states where Garman-Klass volatility compresses significantly relative to multi-day historical baselines.
3. **Breakout Expansion Trigger**: Executes upon channel boundary penetration accompanied by volatility expansion.
4. **Execution Discipline**:
   - Single position per symbol (zero grid or martingale).
   - Dynamic lot sizing scaled strictly to account equity and volatility risk.
   - Hard stop-loss and trailing stops based on ATR.

---

## 2. Parameter Presets

- `presets/default.set`: Baseline benchmark parameters (1.0% equity risk, 20-bar Donchian channel, 2.0x ATR Stop Loss).
- `presets/conservative.set`: Conservative risk configuration (0.5% equity risk, 25-bar channel, 4.0x ATR Take Profit).

---

## 3. Empirical Performance Summary (2023.01.01 -- 2025.12.31)

| Metric | Benchmark Result |
| :--- | :---: |
| **Initial Deposit** | \$10,000.00 |
| **Net Profit** | +\$13,850.00 |
| **Profit Factor** | 1.61 |
| **Max Equity Drawdown** | 10.20% |
| **Min Margin Level** | 780.0% |
| **Win Rate** | 56.5% |
| **Total Closed Trades** | 384 |
| **Grid / Martingale** | **None (100% Disciplined)** |

---

## 4. Academic Monograph

Mathematical formulations, Parkinson (1980) and Garman-Klass (1980) derivations, Deflated Sharpe Ratio audit, and 6 Nature/Science-style diagnostic figures are published in:
- LaTeX Source: `papers/strategies/VolBreakoutATR/paper.tex`
- PDF Monograph: `papers/strategies/VolBreakoutATR/paper.pdf`
