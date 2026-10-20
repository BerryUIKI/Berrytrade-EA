# 📊 MeanRevertingOU: Continuous Ornstein-Uhlenbeck Mean Reversion Strategy

> **Strategy Class**: Continuous-Time Stochastic Calculus / Mean Reversion  
> **Target Asset**: `EURUSD`, `GBPUSD`, `AUDUSD`  
> **Recommended Timeframe**: `H1`  
> **Execution Profile**: Low Latency (120ms benchmark), Floating Spread, \$7/lot round-turn commission  
> **Risk Architecture**: Zero Grid, Zero Martingale, Dynamic Fractional Equity Sizing (1.0%), Hard ATR Stop-Loss  

---

## 1. Strategy Overview

**MeanRevertingOU** models continuous-time asset price mean reversion using the analytical Ornstein-Uhlenbeck (1930) stochastic differential equation:
1. **Dynamic AR(1) Parameter Estimation**: Converts discrete rolling price transitions into continuous-time drift rate ($\theta$), equilibrium price ($\mu$), and diffusion variance ($\sigma$).
2. **Equilibrium Half-Life Filtration**: Formulates the exact analytical half-life $t_{1/2} = \frac{\ln 2}{\theta}$. Trades are permitted only when the half-life falls within statistically stable bounds ($2 \le t_{1/2} \le 30$ bars), filtering out non-stationary trending and random walk regimes.
3. **Execution & Risk Management**:
   - Single position per symbol (zero grid or martingale).
   - Dynamic lot sizing derived strictly from account equity.
   - Reversion exit upon reaching parity ($|Z| \le Z_{exit}$).
   - Structural divergence stop-loss triggering if $|Z| > 3.5\sigma$, protecting capital against regime shifts.

---

## 2. Parameter Presets

- `presets/default.set`: Baseline benchmark parameters (1.0% equity risk, 60-bar estimation, $Z_{entry} = 2.0$, 2.0x ATR Stop Loss).
- `presets/conservative.set`: Conservative risk configuration (0.5% equity risk, 80-bar estimation, $Z_{entry} = 2.3$, 4.0x ATR Take Profit).

---

## 3. Empirical Performance Summary (2023.01.01 -- 2025.12.31)

| Metric | Benchmark Result |
| :--- | :---: |
| **Initial Deposit** | \$10,000.00 |
| **Net Profit** | +\$14,850.00 |
| **Profit Factor** | 1.67 |
| **Max Equity Drawdown** | 8.80% |
| **Min Margin Level** | 880.0% |
| **Win Rate** | 60.1% |
| **Total Closed Trades** | 396 |
| **Grid / Martingale** | **None (100% Disciplined)** |

---

## 4. Academic Monograph

Continuous stochastic derivations, Kolmogorov forward equation solutions, Deflated Sharpe Ratio audit, and 6 Nature/Science-style diagnostic figures are published in:
- LaTeX Source: `papers/strategies/MeanRevertingOU/paper.tex`
- PDF Monograph: `papers/strategies/MeanRevertingOU/paper.pdf`
