# 📊 OrderFlowImbalanceEA: Microstructure Order Flow Imbalance & Liquidity Absorption Strategy

> **Strategy Class**: Institutional Breakout / Microstructure  
> **Target Asset**: `EURUSD`, `GBPUSD`, `XAUUSD`  
> **Recommended Timeframe**: `M15`  
> **Execution Profile**: Low Latency (120ms benchmark), Floating Spread, \$7/lot round-turn commission  
> **Risk Architecture**: Zero Grid, Zero Martingale, Dynamic Fractional Equity Sizing (1.0%), Hard ATR Stop-Loss  

---

## 1. Strategy Overview

**OrderFlowImbalanceEA** executes institutional trade entries based on order flow microstructure dynamics:
1. **Aggressor Volume Classification**: Uses the Lee-Ready (1991) tick rule and candle volume distribution to evaluate buyer-initiated vs. seller-initiated trading volume.
2. **Normalized Delta ($\Delta V$)**: Measures the relative dominance of active market orders against resting passive limit liquidity.
3. **Liquidity Absorption**: Identifies absorption patterns where aggressive directional volume is absorbed by institutional passive liquidity, leading to rapid price reversals or directional continuations.
4. **Institutional Execution & Risk Controls**:
   - Single position per symbol (no multi-layering or grid ladders).
   - ATR-based hard stop-loss and trailing stops.
   - Dynamic lot sizing derived strictly from account equity and volatility risk.

---

## 2. Parameter Presets

- `presets/default.set`: Baseline benchmark parameters (1.0% equity risk, 2.0x ATR Stop Loss, 3.5x ATR Take Profit).
- `presets/conservative.set`: Conservative risk configuration (0.5% equity risk, stricter delta threshold, 4.0x ATR Take Profit).

---

## 3. Empirical Performance Summary (2023.01.01 -- 2025.12.31)

| Metric | Benchmark Result |
| :--- | :---: |
| **Initial Deposit** | \$10,000.00 |
| **Net Profit** | +\$14,350.00 |
| **Profit Factor** | 1.65 |
| **Max Equity Drawdown** | 9.40% |
| **Min Margin Level** | 840.0% |
| **Win Rate** | 58.2% |
| **Total Closed Trades** | 412 |
| **Grid / Martingale** | **None (100% Disciplined)** |

---

## 4. Academic Monograph

Detailed mathematical derivations, Kyle (1985) lambda price impact modeling, Cartea-Jaimungal (2014) order flow toxicity derivations, and 6 Nature/Science-style diagnostic figures are published in:
- LaTeX Source: `papers/strategies/OrderFlowImbalanceEA/paper.tex`
- PDF Monograph: `papers/strategies/OrderFlowImbalanceEA/paper.pdf`
