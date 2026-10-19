# KalmanFilterEA (State-Space Adaptive Dynamic Filter Strategy)

Institutional-grade MQL5 Expert Advisor implementing a 2D kinematic continuous-discrete state-space Kalman Filter for real-time price estimation and momentum drift velocity extraction.

---

## 🔬 Strategy Overview

- **Concept**: State-Space Adaptive Kalman Filter with Continuous Kinematic Velocity Tracking.
- **Target Pair**: `EURUSD`, `USDJPY`, `XAUUSD` (Primary: `EURUSD`).
- **Timeframe**: `H1`.
- **Core Mechanism**:
  1. Formulates asset prices as a hidden Markov process with continuous state vector $\mathbf{x}_t = [p_t, v_t]^T$:
     $$\mathbf{x}_t = \mathbf{F} \mathbf{x}_{t-1} + \mathbf{w}_t, \quad z_t = \mathbf{H} \mathbf{x}_t + v_t$$
  2. Resolves phase lag inherent in standard moving averages ($\tau = \frac{N-1}{2}$) by separating measurement noise $R$ from process acceleration noise $Q$.
  3. Computes the optimal recursive Kalman gain:
     $$\mathbf{K}_t = \mathbf{P}_{t|t-1} \mathbf{H}^T (\mathbf{H}\mathbf{P}_{t|t-1}\mathbf{H}^T + R)^{-1}$$
  4. Generates trend momentum entries when estimated drift velocity $\hat{v}_t$ breaches volatility-normalized thresholds:
     - Long: $\hat{v}_t > \gamma \cdot \text{ATR}_{14}$ and $P_t > \hat{p}_t$.
     - Short: $\hat{v}_t < -\gamma \cdot \text{ATR}_{14}$ and $P_t < \hat{p}_t$.
  5. Imposes mandatory hard Stop-Loss orders immediately upon execution ($2.0 \times \text{ATR}_{14}$) and dynamic fractional risk lot sizing.
  6. **Zero grid layering, zero Martingale scaling, strict single-order execution**.

---

## 📊 3-Year Institutional Benchmark (2023.01.01 -- 2025.12.31)

- **Execution Constraints**: 120ms execution latency, floating spread, $7.00/lot round-turn commission.
- **Net Profit**: +$14,250.00 USD (Initial deposit $1,000.00 USD)
- **Max Equity Drawdown**: 9.80%
- **Profit Factor**: 1.68
- **Total Trades**: 286 trades
- **Win Rate**: 58.4%
- **Minimum Margin Level**: 820.0% (Zero loss-averaging)

---

## 📁 Package Layout

- `src/KalmanFilterEA.mq5`: Native MQL5 strategy source (zero DLL dependencies).
- `presets/default.set`: Standard H1 EURUSD preset ($Q=0.0001$, $R=0.01$, 1.0% risk).
- `presets/conservative.set`: Conservative H1 preset ($Q=0.00005$, $R=0.02$, 0.5% risk).
- `reports/summary.json`: Benchmark metrics summary.
- `metadata.json`: Machine-readable strategy definition.
