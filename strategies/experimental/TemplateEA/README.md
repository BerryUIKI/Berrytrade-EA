# TemplateEA - Standard Strategy Implementation

`TemplateEA` serves as the reference template for contributing Expert Advisors to the **Berrytrade-EA** repository.

---

## 1. Overview & Economics
- **Category**: `trend_following`
- **Recommended Symbols**: XAUUSD, EURUSD
- **Timeframe**: M5
- **Risk Level**: Low (Mandatory Hard Stop-Loss, No Martingale, No Grid)

---

## 2. Core Trade Logic
- **Entry Signal**: Dual Exponential Moving Average (EMA) fast/slow crossover.
- **Exit Signal**: Opposite crossover or ATR Trailing Stop.
- **Stop Loss**: Strict ATR-based hard stop loss placed on order send.
- **Overnight Policy**: All positions are closed before session rollover.

---

## 3. Key Parameters
| Parameter | Default | Description |
| :--- | :--- | :--- |
| `InpFastPeriod` | `10` | Fast EMA calculation period |
| `InpSlowPeriod` | `30` | Slow EMA calculation period |
| `InpRiskPercent` | `0.5` | Risk percent per trade (% of equity) |
| `InpStopLossPoints` | `150.0` | Initial protective stop-loss (Points) |
| `InpTakeProfitPoints` | `300.0` | Target take-profit (Points) |
