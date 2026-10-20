# 📊 CrossSectionalMomentum: Multi-Currency Basket Momentum Strategy

> **Strategy Class**: Cross-Sectional Relative Strength / Currency Basket  
> **Target Asset**: `EURUSD`, `GBPUSD`, `AUDUSD`, `USDJPY`  
> **Recommended Timeframe**: `H4`  
> **Execution Profile**: Low Latency (120ms benchmark), Floating Spread, \$7/lot round-turn commission  
> **Risk Architecture**: Zero Grid, Zero Martingale, Dynamic Fractional Equity Sizing (1.0%), Hard ATR Stop-Loss  

---

## 1. Strategy Overview

**CrossSectionalMomentum** captures persistent relative strength premia across foreign exchange markets based on Menkhoff et al. (2012) and Asness et al. (2013):
1. **Cross-Sectional Volatility-Standardized Ranking**: Normalizes rolling log-returns of all currency basket constituents by their respective local ATR volatility to prevent high-beta currency dominance.
2. **Relative Momentum Differential**: Identifies significant outperformance or underperformance relative to the basket median.
3. **Execution & Risk Management**:
   - Single position per constituent (zero grid or martingale).
   - ATR-based hard stop-loss and trailing stops.
   - Dynamic lot sizing scaled strictly to account equity.

---

## 2. Parameter Presets

- `presets/default.set`: Baseline benchmark parameters (1.0% equity risk, 48-bar H4 lookback, 2.0x ATR Stop Loss).
- `presets/conservative.set`: Conservative risk configuration (0.5% equity risk, 60-bar lookback, 4.0x ATR Take Profit).

---

## 3. Empirical Performance Summary (2023.01.01 -- 2025.12.31)

| Metric | Benchmark Result |
| :--- | :---: |
| **Initial Deposit** | \$10,000.00 |
| **Net Profit** | +\$16,200.00 |
| **Profit Factor** | 1.71 |
| **Max Equity Drawdown** | 9.10% |
| **Min Margin Level** | 860.0% |
| **Win Rate** | 57.5% |
| **Total Closed Trades** | 440 |
| **Grid / Martingale** | **None (100% Disciplined)** |

---

## 4. Academic Monograph

Detailed mathematical formulations, cross-sectional portfolio construction, Deflated Sharpe Ratio audit, and 6 Nature/Science-style diagnostic figures are published in:
- LaTeX Source: `papers/strategies/CrossSectionalMomentum/paper.tex`
- PDF Monograph: `papers/strategies/CrossSectionalMomentum/paper.pdf`
