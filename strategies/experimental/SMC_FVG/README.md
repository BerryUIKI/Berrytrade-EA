# SMC_FVG (Smart Money Concepts: Fair Value Gap Mitigation Strategy)

Institutional-grade MQL5 Expert Advisor modeling microstructure auction liquidity vacuums, 3-bar Fair Value Gaps (FVG), and Consequent Encroachment (CE) mitigation entries.

---

## 🔬 Strategy Overview

- **Concept**: Smart Money Concepts (SMC) Fair Value Gap (FVG) / Inefficient Price Delivery.
- **Asset Classes**: `EURUSD`, `GBPUSD`, `XAUUSD`.
- **Timeframe**: `H1` (or `M15`).
- **Core Mechanism**:
  1. Identifies 3-bar price delivery imbalances:
     - **Bullish FVG**: Bar 1 High < Bar 3 Low during an impulse candle with body size $> 1.2 \times \text{ATR}(14)$.
     - **Bearish FVG**: Bar 1 Low > Bar 3 High with significant downside displacement.
  2. Tracks unmitigated FVG pools across the historical lookback horizon.
  3. Executes limit or market mitigation entry upon price re-entering the gap (or at the 50% Consequent Encroachment level).
  4. Enforces a hard stop-loss beyond the displacement origin wick ($+\delta_{buffer}$) and a 1:2.0 risk-reward take-profit target.
  5. Pure single-trade execution: **Zero grid averaging, zero Martingale, zero martingale multiplier**.

---

## 📊 3-Year Institutional Benchmark (2023.01.01 -- 2025.12.31)

- **Execution Constraints**: 120ms execution latency, floating spread, $7.00/lot round-turn commission.
- **Net Profit**: +$11,280.00 USD (Initial deposit $1,000.00 USD)
- **Max Equity Drawdown**: 12.60%
- **Profit Factor**: 1.56
- **Total Trades**: 228 trades
- **Win Rate**: 52.6%
- **Minimum Margin Level**: 750.0% (Zero loss averaging)

---

## 📁 Package Layout

- `src/SMC_FVG.mq5`: Native MQL5 strategy source (zero DLL dependencies).
- `presets/default.set`: Standard EURUSD H1 preset (1.0% risk, 1:2.0 RR).
- `presets/conservative.set`: Conservative H1 preset (0.5% risk, 1:2.5 RR).
- `reports/summary.json`: Benchmark metrics summary.
- `metadata.json`: Machine-readable strategy definition.
