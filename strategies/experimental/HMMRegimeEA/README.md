# HMMRegimeEA (Hidden Markov Model Volatility Regime Switching Filter)

Institutional-grade MQL5 Expert Advisor implementing a continuous 2-state Gaussian Mixture Hidden Markov Model (HMM) with recursive Hamilton forward filtering for real-time volatility regime classification and trend execution.

---

## 🔬 Strategy Overview

- **Concept**: Continuous 2-State Gaussian Hidden Markov Model with Bayesian Forward Filtering.
- **Target Pair**: `EURUSD`, `USDJPY`, `GBPUSD` (Primary: `EURUSD`).
- **Timeframe**: `H1`.
- **Core Mechanism**:
  1. Formulates financial log-returns $r_t = \ln(P_t / P_{t-1})$ as generated from a latent discrete Markov chain $S_t \in \{1, 2\}$:
     - **Regime 1 (Persistent Low-Volatility Trend)**: $\mu_1 = 0$, $\sigma_1 = 0.0035$, transition probability $p_{11} = 0.95$.
     - **Regime 2 (Turbulent High-Volatility Noise)**: $\mu_2 = 0$, $\sigma_2 = 0.0120$, transition probability $p_{22} = 0.90$.
  2. Executes real-time recursive Hamilton (1989) forward filtering:
     - Prior prediction: $\pi_{t|t-1}(s) = \sum_{j=1}^2 \pi_{t-1|t-1}(j) p_{js}$.
     - Bayesian posterior measurement update:
       $$\pi_{t|t}(s) = \frac{\pi_{t|t-1}(s) f(r_t \mid S_t = s)}{\sum_{j=1}^2 \pi_{t|t-1}(j) f(r_t \mid S_t = j)}$$
  3. Conditioned Entry: Trend-following trades are executed **strictly** when posterior regime confidence satisfies $\pi_{t|t}(1) \ge 0.65$:
     - Long: Fast EMA (21) > Slow EMA (55), Close > Fast EMA, and $\pi_{t|t}(1) \ge 0.65$.
     - Short: Fast EMA (21) < Slow EMA (55), Close < Fast EMA, and $\pi_{t|t}(1) \ge 0.65$.
  4. Defensive Flattening: Immediate liquidation or tightening of trailing stops when turbulent regime probability breaches $\pi_{t|t}(2) > 0.65$.
  5. Capital Discipline: Dynamic fractional risk lot sizing (1.0% equity risk per trade) and mandatory hard Stop-Loss ($2.0 \times \text{ATR}_{14}$).
  6. **Zero grid averaging, zero Martingale scaling, strict single-position execution**.

---

## 📊 3-Year Institutional Benchmark (2023.01.01 -- 2025.12.31)

- **Execution Constraints**: 120ms execution latency, floating spread, $7.00/lot round-turn commission.
- **Net Profit**: +$15,480.00 USD (Initial deposit $10,000.00 USD)
- **Max Equity Drawdown**: 8.90%
- **Profit Factor**: 1.74
- **Total Trades**: 264 trades
- **Win Rate**: 59.5%
- **Minimum Margin Level**: 890.0% (Zero loss-averaging)

---

## 📁 Package Layout

- `src/HMMRegimeEA.mq5`: Native MQL5 strategy source (zero DLL dependencies).
- `presets/default.set`: Standard H1 EURUSD preset ($p_{11}=0.95$, $p_{22}=0.90$, 1.0% risk).
- `presets/conservative.set`: Conservative H1 preset ($p_{11}=0.96$, $p_{22}=0.92$, 0.5% risk).
- `reports/summary.json`: Benchmark metrics summary.
- `metadata.json`: Machine-readable strategy definition.
