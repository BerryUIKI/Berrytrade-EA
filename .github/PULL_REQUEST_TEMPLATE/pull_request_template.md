## 📌 Pull Request: EA Submission & Review

> Please fill in all relevant sections below. Ensure all documentation and comments are in English.

### 1. Strategy Overview
- **Strategy Name**: 
- **Target Tier**: `strategies/experimental/` (Default for new submissions)
- **Primary Category**: [ ] `trend_following` [ ] `mean_reversion` [ ] `breakout` [ ] `scalping` [ ] `grid` [ ] `martingale` [ ] Other: 
- **Risk Level**: [ ] `Low` [ ] `Medium` [ ] `High` [ ] `Extreme`
- **Supported Symbols**: 
- **Recommended Timeframe**: 

---

### 2. Risk & Operational Disclosures
- [ ] Hard Stop-Loss is **strictly enforced** on all trades.
- [ ] Uses Martingale (lot multiplier on loss)? [ ] Yes [ ] No (If yes, `"risk_level"` must be set to `Extreme`)
- [ ] Uses Grid without multiplier? [ ] Yes [ ] No
- [ ] Allows overnight / weekend holding? [ ] Yes [ ] No
- [ ] Requires external DLL or Win32 imports? [ ] Yes [ ] No *(Native DLL imports are strictly prohibited)*

---

### 3. Submission Checklist (Strategy Package Layout)
- [ ] EA source file located at `strategies/experimental/<StrategyName>/src/<StrategyName>.mq5`
- [ ] Presets file located at `strategies/experimental/<StrategyName>/presets/<PresetName>.set`
- [ ] Backtest report/summary located at `strategies/experimental/<StrategyName>/reports/summary.json`
- [ ] Strategy specification `metadata.json` present and conforms to schema
- [ ] Strategy documentation `README.md` included (covering logic, parameters, and risk)
- [ ] Passed local validation script: `python tools/validate_ea.py --path strategies/experimental/<StrategyName>`
- [ ] Verified that code compiles cleanly on MetaTrader 5 without errors

---

### 4. Backtest Snapshot Summary
- **Test Period**: 
- **Initial Deposit**: 
- **Profit Factor**: 
- **Max Equity Drawdown (%)**: 
- **Total Trades**: 
- **Win Rate (%)**: 

---

### 5. Strategy Summary & Algorithm Rationale
*Provide a concise explanation of the entry logic, exit logic, indicator calculations, and key risk control rules.*
