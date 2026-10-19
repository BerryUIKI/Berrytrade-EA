# Benchmarking & Backtest Standards

To ensure objective and reproducible evaluation of all trading strategies submitted to **Berrytrade-EA**, all backtests must follow these benchmarking guidelines.

---

## 1. Core Testing Requirements

1. **Modeling Quality**:
   - Backtests must use **"Every tick based on real ticks"** in the MetaTrader 5 Strategy Tester.
   - Do not use "1 minute OHLC" or "Open prices only" for final submission unless the EA strictly executes only on candle open.
2. **Realistic Friction & Costs**:
   - Model realistic spreads (refer to `standards.json`).
   - Include broker commissions (default $7.00 per round-turn lot).
   - Test under both floating and fixed spread conditions.
3. **Sample Size & Robustness**:
   - Backtest duration must span at least **3 consecutive years** of market data.
   - Strategy must execute at least **200 trades** to establish statistical confidence.
   - Maximum recommended equity drawdown must remain under **20%**.

---

## 2. Standard Reporting Output

When submitting an EA, include the key metrics summary in `reports/summary.json`:
```json
{
  "test_period": "2023.01.01 - 2025.12.31",
  "symbol": "XAUUSD",
  "timeframe": "M5",
  "initial_deposit": 1000.0,
  "net_profit": 452.10,
  "profit_factor": 1.48,
  "max_equity_drawdown_percent": 11.2,
  "recovery_factor": 4.03,
  "total_trades": 248,
  "win_rate_percent": 53.6
}
```
