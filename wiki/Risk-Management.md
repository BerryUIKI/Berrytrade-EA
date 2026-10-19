# Risk Management & Money Management Rules

<p align="center">
  <a href="Risk-Management"><strong>English</strong></a> | 
  <a href="Risk-Management-zh"><strong>简体中文</strong></a>
</p>

Quantitative trading without disciplined risk management leads to inevitable account destruction. This guide provides fundamental money management principles for users of Berrytrade-EA strategies.

---

## 1. The 1% Rule
Never risk more than **0.5% to 1.0%** of your total account equity on any single trade.

For example, on a $1,000 account:
- **0.5% Risk**: Maximum allowable loss per trade = **$5.00**
- **1.0% Risk**: Maximum allowable loss per trade = **$10.00**

If an EA calculates that the minimum trade volume (e.g. 0.01 lots on XAUUSD) exceeds your dollar risk budget given the required stop-loss distance, the trade **must be skipped**.

---

## 2. Understanding Strategy Risk Tiers

Every strategy in Berrytrade-EA is assigned a risk category:

| Tier / Label | Category | Typical Drawdown | Safety Features |
| :--- | :--- | :---: | :--- |
| 🟢 **Low Risk** | Trend Following, High-Timeframe Swing | $< 10\%$ | Strict hard stop-loss, no martingale, no grid |
| 🟡 **Medium Risk** | Mean Reversion, Channel Breakout | $10\% - 20\%$ | Hard stop-loss, trailing stop, whipsaw exposure |
| 🟠 **High Risk** | Scalping (M1), Volatility Breakout | $20\% - 30\%$ | Spread-sensitive, requires low-latency VPS |
| 🔴 **Extreme Risk** | Martingale, Uncapped Grid | **$50\% - 100\%$** | Multiplies lots after losses. **High probability of total capital loss** |

> [!CAUTION]
> If a strategy is tagged **Extreme Risk**, it multiplies positions against the market trend. It may generate consistent small profits for weeks, only to suffer a sudden 100% account blowout during extended trend moves.

---

## 3. Account Leverage & Margin Call Protection

- High leverage (e.g. 1:500 or 1:1000) does not make you more money—it only allows you to open larger, more dangerous position sizes.
- We recommend operating with effective account leverage between **1:30 and 1:100**.
- Always maintain an equity margin level well above **500%**.

---

## 4. Weekend & Overnight Risk Policy

- Market opens on Sunday evening often produce **price gaps** due to weekend geopolitical news.
- Stop-loss orders do NOT protect against weekend price gaps—orders are executed at the first available open market price.
- We recommend enabling `InpCloseBeforeWeekend = true` in all EA presets to liquidate open exposures before Friday market close.
