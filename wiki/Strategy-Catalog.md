# Strategy Catalog & Selection Guide

<p align="center">
  <a href="Strategy-Catalog"><strong>English</strong></a> | 
  <a href="Strategy-Catalog-zh"><strong>简体中文</strong></a>
</p>

This page provides an overview of available Expert Advisors in the Berrytrade-EA repository, helping you select the appropriate strategy for your account size, symbol preference, and market view.

---

## Active Strategies

### 1. TemplateEA
- **Tier**: `experimental`
- **Class**: Trend Following
- **Recommended Symbols**: `XAUUSD`, `EURUSD`
- **Timeframe**: `M5`
- **Risk Level**: 🟢 Low
- **Minimum Recommended Capital**: $1,000 USD
- **Strategy Summary**: Demonstrates dual EMA crossover trend-following logic combined with account-equity risk sizing, ATR hard stop loss, and weekend liquidation safeguards.
- **Source Link**: [TemplateEA Folder](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/TemplateEA)

---

## Strategy Selection Matrix

| Market Regime | Recommended Class | Risk Consideration |
| :--- | :--- | :--- |
| **Strong Trend** | Trend Following (`trend_following`) | Maximizes profit runs; suffers small whipsaws during consolidation |
| **Range-Bound / Consolidating** | Mean Reversion (`mean_reversion`) | Profits from oscillation; must have hard stops against breakouts |
| **High Volatility (London/NY Open)** | Breakout (`breakout`) | High win rate on strong momentum; vulnerable to fake breakouts |
| **Quiet Asian Session** | Scalping (`scalping`) | Dependent on raw spreads under 1.5 pips and sub-10ms VPS execution |

---

## How to Request or Propose a Strategy

Have a strategy idea or indicator you want ported to MQL5?
1. Check existing issues or submit a [Strategy Proposal Issue](https://github.com/BerryUIKI/Berrytrade-EA/issues/new?template=ea_submission_proposal.md).
2. Quant developers in our open-source community actively pick up proposals for research and development.
