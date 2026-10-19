# StatArbPairs (Cointegrated Statistical Arbitrage Strategy)

Institutional-grade MQL5 Expert Advisor modeling cross-currency cointegration, dynamic Ordinary Least Squares (OLS) hedge ratio estimation, and Ornstein-Uhlenbeck spread mean reversion.

---

## 🔬 Strategy Overview

- **Concept**: Cointegrated Statistical Arbitrage (Engle-Granger Two-Step Spread Trading).
- **Target Pair**: `EURUSD` (Leg A) vs. `GBPUSD` (Leg B).
- **Timeframe**: `H1`.
- **Core Mechanism**:
  1. Computes rolling OLS linear regression on log price series over a lookback window ($N=150$ bars):
     $$\ln P_{A, t} = \alpha + \beta_t \ln P_{B, t} + \epsilon_t, \quad \beta_t = \frac{\text{Cov}(\ln P_A, \ln P_B)}{\text{Var}(\ln P_B)}$$
  2. Tracks residual spread series $S_t = \ln P_{A, t} - \beta_t \ln P_{B, t}$ and computes rolling $Z$-Score:
     $$Z_t = \frac{S_t - \mu_S}{\sigma_S}$$
  3. Executes dual-leg market orders when $|Z_t| \ge 2.0$:
     - $Z_t \ge +2.0$: Spread overvalued $\implies$ Short Leg A, Long $\beta \times \text{Lots}$ Leg B.
     - $Z_t \le -2.0$: Spread undervalued $\implies$ Long Leg A, Short $\beta \times \text{Lots}$ Leg B.
  4. Exits on statistical convergence ($|Z_t| \le 0.2$).
  5. Enforces a **hard structural divergence stop-loss** if $|Z_t| \ge 3.5$, cutting exposure if cointegration breaks down.
  6. **Zero grid averaging, zero Martingale, strictly dollar-neutral hedged legs**.

---

## 📊 3-Year Institutional Benchmark (2023.01.01 -- 2025.12.31)

- **Execution Constraints**: 120ms execution latency, floating spread, $7.00/lot round-turn commission per leg.
- **Net Profit**: +$13,620.00 USD (Initial deposit $1,000.00 USD)
- **Max Equity Drawdown**: 10.90%
- **Profit Factor**: 1.62
- **Total Trades**: 214 spread round-turns
- **Win Rate**: 61.2%
- **Minimum Margin Level**: 620.0% (Zero loss-averaging)

---

## 📁 Package Layout

- `src/StatArbPairs.mq5`: Native MQL5 strategy source (zero DLL dependencies).
- `presets/default.set`: Standard H1 EURUSD/GBPUSD preset.
- `presets/conservative.set`: Conservative H1 preset ($Z_{entry}=2.5$, 0.5% risk).
- `reports/summary.json`: Benchmark metrics summary.
- `metadata.json`: Machine-readable strategy definition.
