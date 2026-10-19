# TurtleTrader

## 1. Strategy Overview
- **Taxonomy**: `trend_following`
- **Original Authors**: Richard Dennis & William Eckhardt (1983 Turtle Trading Experiment)
- **MQL5 Refactoring**: Berry Wahlberg (`Berrytrade Quantitative Research`)
- **Primary Assets**: EURUSD, XAUUSD, GBPUSD
- **Recommended Timeframe**: Daily (`D1`)
- **Risk Level**: **Medium** (Uses Grid: `False`, Strict Hard Stop Loss: `True`)

---

## 2. Quantitative Model & Trading Rules

The **TurtleTrader** Expert Advisor implements the complete mathematical rule set of the legendary Turtle Trading experiment:

### 2.1 Volatility & Position Sizing ($N$)
1. **$N$ Definition**: 20-period Exponential Moving Average of True Range ($TR$):
   $$TR_t = \max(H_t - L_t, |H_t - C_{t-1}|, |L_t - C_{t-1}|)$$
   $$N_t = \frac{19 \times N_{t-1} + TR_t}{20}$$
2. **Dollar Volatility**: $\text{DV} = N \times \text{PointValue} \times \frac{\text{TickValue}}{\text{TickSize}}$
3. **Unit Sizing**:
   $$\text{Unit} = \text{NormalizeLot}\left(\frac{\text{Equity} \times \text{InpRiskPercent}}{\text{DV}}\right)$$

### 2.2 Breakout Execution Rules
- **System 1 (Short-Term)**:
  - **Long Entry**: Daily close crosses above the 20-day High: $C_t > \max_{1 \le i \le 20}(H_{t-i})$.
  - **Short Entry**: Daily close crosses below the 20-day Low: $C_t < \min_{1 \le i \le 20}(L_{t-i})$.
  - **Long Exit**: Daily low crosses below the 10-day Low: $L_t < \min_{1 \le i \le 10}(L_{t-i})$.
  - **Short Exit**: Daily high crosses above the 10-day High: $H_t > \max_{1 \le i \le 10}(H_{t-i})$.
- **System 2 (Long-Term, Conservative)**:
  - **Entry**: 55-day High/Low breakout.
  - **Exit**: 20-day High/Low breakout.

### 2.3 Risk Control & Dynamic Pyramiding
- **Mandatory Hard Stop-Loss**: Placed at $2N$ (2 ATR) from the entry price immediately upon fill:
  $$\text{SL}_{long} = P_{entry} - 2N, \quad \text{SL}_{short} = P_{entry} + 2N$$
- **Pyramiding (Adding Units)**: Up to 4 Units max (`InpMaxUnits`), added each time the market advances by $0.5N$ in favor.
- **Trailing Stop Consolidation**: When an additional unit is added, all existing open units have their Stop Loss trailed by $0.5N$, ensuring total account risk never exceeds $2N$.

---

## 3. Parameter Presets
- `presets/default.set`: System 1 (20/10 Breakout, 1.0% Risk/Unit, Max 4 Units)
- `presets/conservative.set`: System 2 (55/20 Breakout, 0.5% Risk/Unit, Max 2 Units)

---

## 4. Academic Monograph
A full research monograph analyzing the 3-year execution benchmark (2023--2025) of `TurtleTrader` is available at [papers/strategies/TurtleTrader/paper.pdf](../../../papers/strategies/TurtleTrader/paper.pdf).
