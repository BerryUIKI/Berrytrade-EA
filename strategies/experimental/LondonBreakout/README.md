# LondonBreakout (Asian Range Liquidity Shock Strategy)

Institutional-grade MQL5 Expert Advisor capturing directional momentum expansions triggered by European interbank market openings.

---

## 🔬 Strategy Overview

- **Concept**: Asian Session Consolidation Breakout (London / European Open Liquidity Shock).
- **Asset Classes**: `GBPUSD`, `EURUSD`, `EURGBP`.
- **Timeframe**: `M15` (or `M30`).
- **Core Mechanism**:
  1. Computes the Asian session high and low corridor between 00:00 and 07:00 broker time.
  2. Applies box height sanity bounds ($150 \le \text{Range} \le 800$ points) to reject non-tradable regimes (extreme news shock or flat holidays).
  3. Executes single-shot breakout entry upon confirmation bar close above Asian High + Buffer or below Asian Low - Buffer.
  4. Enforces hard stop loss at the opposite box boundary and dynamic 1.5x risk-reward take-profit.
  5. **Zero Overnight Carryover**: Automatically liquidates all active exposure at 19:00 broker time, totally eliminating overnight rollover swap charges and flash crash gap risk.

---

## 📊 3-Year Institutional Benchmark (2023.01.01 -- 2025.12.31)

- **Execution Constraints**: 120ms execution latency, floating spread, $7.00/lot round-turn commission.
- **Net Profit**: +$9,820.00 USD (Initial deposit $1,000.00 USD)
- **Max Equity Drawdown**: 13.40%
- **Profit Factor**: 1.48
- **Total Trades**: 342 trades
- **Win Rate**: 48.2%
- **Minimum Margin Level**: 850.0% (Zero grid, zero martingale)

---

## 📁 Package Layout

- `src/LondonBreakout.mq5`: Native MQL5 strategy source (zero DLL dependencies).
- `presets/default.set`: Standard GBPUSD M15 preset.
- `presets/conservative.set`: Conservative EURUSD M15 preset (0.5% risk).
- `reports/summary.json`: Benchmark metrics summary.
- `metadata.json`: Machine-readable strategy definition.
