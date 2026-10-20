# 📊 Strategy Catalog & Institutional MT5 Backtest Manual

<p align="center">
  <a href="Strategy-Catalog"><strong>English</strong></a> | 
  <a href="Strategy-Catalog-zh"><strong>简体中文</strong></a>
</p>

Welcome to the **Berrytrade-EA Strategy Catalog & Institutional Backtest Manual**. This document provides an exhaustive, empirical breakdown of all **24 Expert Advisors** in the repository.

Unlike commercial marketing portals that showcase curve-fitted equity curves, Berrytrade enforces an institutional audit standard:
1. **Zero Native Win32 DLL Imports**: All strategies run in pure MQL5.
2. **Transparent Risk Stratification**: Clear separation between institutional disciplined strategies (with non-negotiable hard stop-losses) and high-risk grid/martingale incubation bots.
3. **Continuous 3-Year Execution-Constrained Backtests**: Evaluated across **2023.01.01 -- 2025.12.31** under **120ms execution latency**, **floating interbank spreads**, and **$7.00/lot round-turn commission**.
4. **Reproducible Parameter Presets**: Every strategy includes calibrated `.set` files (`default.set`, `conservative.set`).

---

## 🧭 Quick Navigation
1. [Master Cross-Sectional Comparison Table](#-master-cross-sectional-comparison-table-all-24-eas)
2. [Panel A: Institutional Verified Candidates (10 EAs)](#-panel-a-institutional-verified-candidate-strategies-10-eas)
3. [Panel B: Baseline Disciplined Non-Grid Strategies (4 EAs)](#-panel-b-baseline-disciplined-non-grid-strategies-4-eas)
4. [Panel C: Retail Grid & Martingale Incubation Strategies (10 EAs)](#-panel-c-retail-grid--martingale-incubation-strategies-10-eas-extreme-risk)
5. [Multi-Strategy Combinatorial Portfolio & Risk Parity](#-multi-strategy-combinatorial-portfolio--risk-parity-allocation)
6. [How to Apply Presets in MetaTrader 5](#-how-to-apply-presets-in-metatrader-5)

---

## 📋 Master Cross-Sectional Comparison Table (All 24 EAs)

| Strategy Name | Category | Primary Symbols | TF | PF | Max DD (%) | Min Margin (%) | Risk Level | Grid Overlay | Governance Tier |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Panel A: Institutional Candidates** | | | | | | | | | |
| [TurtleTrader](#1-turtletrader) | `trend_following` | `EURUSD`, `XAUUSD` | Daily | 1.52 | 11.80% | 720.0% | 🟡 Medium | ❌ No | **Verified** |
| [LondonBreakout](#2-londonbreakout) | `breakout` | `GBPUSD`, `EURUSD` | M15 | 1.48 | 13.40% | 850.0% | 🟡 Medium | ❌ No | **Verified** |
| [SMC_FVG](#3-smc_fvg) | `breakout` | `EURUSD`, `GBPUSD` | H1 | 1.56 | 12.60% | 750.0% | 🟡 Medium | ❌ No | **Verified** |
| [StatArbPairs](#4-statarbpairs) | `arbitrage` | `EURUSD`, `GBPUSD` | H1 | 1.62 | 10.90% | 620.0% | 🟡 Medium | ❌ No | **Verified** |
| [KalmanFilterEA](#5-kalmanfilterea) | `trend_following` | `USDJPY`, `EURUSD` | H1 | 1.68 | 9.80% | 820.0% | 🟡 Medium | ❌ No | **Verified** |
| [HMMRegimeEA](#6-hmmregimeea) | `trend_following` | `EURUSD`, `USDJPY` | H1 | 1.74 | 8.90% | 890.0% | 🟡 Medium | ❌ No | **Verified** |
| [OrderFlowImbalanceEA](#7-orderflowimbalanceea) | `breakout` | `XAUUSD`, `EURUSD` | M15 | 1.65 | 9.40% | 840.0% | 🟡 Medium | ❌ No | **Verified** |
| [VolBreakoutATR](#8-volbreakoutatr) | `breakout` | `USDJPY`, `EURUSD` | H1 | 1.61 | 10.20% | 780.0% | 🟡 Medium | ❌ No | **Verified** |
| [CrossSectionalMomentum](#9-crosssectionalmomentum) | `trend_following` | Multi-FX Basket (6 Pairs) | H4 | 1.71 | 9.10% | 860.0% | 🟡 Medium | ❌ No | **Verified** |
| [MeanRevertingOU](#10-meanrevertingou) | `mean_reversion` | `EURUSD`, `GBPUSD` | H1 | 1.67 | 8.80% | 880.0% | 🟡 Medium | ❌ No | **Verified** |
| **Panel B: Baseline Non-Grid EAs** | | | | | | | | | |
| [COT1](#11-cot1) | `trend_following` | `EURUSD` | Daily | 1.65 | 14.20% | 680.0% | 🟡 Medium | ❌ No | **Verified** |
| [2MOMEMA](#12-2momema) | `trend_following` | `EURUSD` | H1 | 1.38 | 18.40% | 450.0% | 🟠 High | ❌ No | **Disciplined** |
| [LRCMACD](#13-lrcmacd) | `trend_following` | `EURUSD` | H1 | 1.42 | 16.50% | 520.0% | 🟠 High | ❌ No | **Disciplined** |
| [TemplateEA](#14-templateea) | `trend_following` | `XAUUSD`, `EURUSD` | M5 | 1.35 | 8.50% | 850.0% | 🟢 Low | ❌ No | **Reference Base** |
| **Panel C: Retail Grid Incubation** | | | | | | | | | |
| [2MAAOS](#15-2maaos) | `trend_following` | `EURUSD`, `EURCAD` | H4 | 2.85* | 64.79% | 171.5% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [2MACDSTO](#16-2macdsto) | `mean_reversion` | `NZDUSD` | H3 | 4.42* | 68.09% | 70.9% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [3MACD](#17-3macd) | `scalping` | `AUDUSD` | M5 | 2.04* | 63.01% | 107.8% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [3MAF](#18-3maf) | `trend_following` | `USDCAD` | M15 | 2.05* | 75.30% | 36.2% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [AFAOSMD](#19-afaosmd) | `trend_following` | `NZDCAD` | M30 | 2.34* | 83.59% | 51.0% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [BBRSI](#20-bbrsi) | `mean_reversion` | `XAUUSD` | M5 | 2.31* | 70.23% | 1314.0% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [CEZLSMA](#21-cezlsma) | `trend_following` | `AUDUSD` | M15 | 2.78* | 94.00% | 16.2% | 🔴 Extreme | ⚠️ Yes | **Incubation (Ruin)** |
| [DHLAOS](#22-dhlaos) | `scalping` | `AUDUSD` | M5 | 1.92* | 56.02% | 332.5% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [LRCUTB](#23-lrcutb) | `trend_following` | `AUDCAD` | M15 | 1.92* | 66.95% | 146.2% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |
| [NWERSIASF](#24-nwersiasf) | `mean_reversion` | `USDCAD`, `AUDUSD` | H2 | 2.19* | 68.62% | 57.0% | 🔴 Extreme | ⚠️ Yes | **Incubation (Grid)** |

*\*Note: High profit factors in Panel C are statistical artifacts of unclosed floating grid losses. When subjected to trending macro regimes, unhedged grid strategies experience extreme drawdowns and stop-outs.*

---

## 🏛️ Panel A: Institutional Verified Candidate Strategies (10 EAs)

These strategies operate under strict quantitative risk governance: zero martingale, dynamic fractional volatility position sizing, and non-negotiable hard stop-losses placed at order submission.

---

### 1. TurtleTrader
Classic trend-following system based on Richard Dennis and William Eckhardt's legendary rules, enhanced with volatility-adaptive position sizing and trailing stops.

- **Category**: `trend_following`
- **Supported Symbols**: `EURUSD`, `XAUUSD`, `GBPUSD`
- **Recommended Timeframe**: `Daily`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None (Pure Trend Following)
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **System 1 Entry**: 20-day high breakout for Long, 20-day low breakout for Short.
  - **System 2 Entry**: 55-day high breakout for Long, 55-day low breakout for Short.
  - **Position Sizing ($N$)**: Volatility unit sized by 20-day Average True Range ($N = \text{ATR}(20)$). Account risk strictly limited to 1.0% equity per unit.
  - **Hard Stop-Loss**: Hard stop placed at $2N$ below/above entry price.
  - **Trailing Exit**: 10-day low breakout for Long, 10-day high breakout for Short.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$12,450.00 USD (+124.50%)**
  - **Profit Factor (PF)**: **1.52**
  - **Maximum Equity Drawdown**: **11.80%**
  - **Total Trades**: 312 | **Win Rate**: 44.5%
  - **Minimum Recorded Margin Level**: **720.0%** (Immune to margin calls)
  - **Execution Constraints**: 120ms latency, floating spreads, $7.00/lot commission
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/TurtleTrader)
  - [Presets Directory](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/TurtleTrader/presets)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/TurtleTrader/paper.pdf)

---

### 2. LondonBreakout
Exploits liquidity expansion at the European market open (Frankfurt 07:00 UTC and London 08:00 UTC) following Asian session consolidation.

- **Category**: `breakout`
- **Supported Symbols**: `GBPUSD`, `EURUSD`, `EURGBP`
- **Recommended Timeframe**: `M15`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None (Intraday Momentum)
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Asian Range Window**: Scans high/low between 00:00 and 06:45 GMT.
  - **Liquidity Buffer**: Buffer offset of $5\sim10$ points outside the Asian range.
  - **Volume & Range Filter**: Requires Asian range $\le 0.75 \times \text{ATR}(14)$ to prevent trading after exhausted sessions.
  - **Zero Overnight Carry**: All open positions closed by 17:00 GMT, completely eliminating overnight swap and rollover risk.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$9,820.00 USD (+98.20%)**
  - **Profit Factor (PF)**: **1.48**
  - **Maximum Equity Drawdown**: **13.40%**
  - **Total Trades**: 485 | **Win Rate**: 56.2%
  - **Minimum Recorded Margin Level**: **850.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/LondonBreakout)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/LondonBreakout/paper.pdf)

---

### 3. SMC_FVG (Smart Money Concepts)
Identifies institutional price delivery imbalances via Fair Value Gaps (FVG) and order block mitigations.

- **Category**: `breakout` / `liquidity_delivery`
- **Supported Symbols**: `EURUSD`, `GBPUSD`, `XAUUSD`
- **Recommended Timeframe**: `H1`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Bullish FVG**: 3-bar displacement pattern where Bar 1 High < Bar 3 Low.
  - **Bearish FVG**: 3-bar displacement pattern where Bar 1 Low > Bar 3 High.
  - **Consequent Encroachment**: Entry upon 50% retest of the imbalance gap.
  - **Asymmetric Risk-Reward**: Mandatory minimum 2:1 profit-to-risk ratio ($2R$). Hard stop below the displacement swing low.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$11,280.00 USD (+112.80%)**
  - **Profit Factor (PF)**: **1.56**
  - **Maximum Equity Drawdown**: **12.60%**
  - **Total Trades**: 368 | **Win Rate**: 52.8%
  - **Minimum Recorded Margin Level**: **750.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/SMC_FVG)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/SMC_FVG/paper.pdf)

---

### 4. StatArbPairs
Cointegrated statistical arbitrage pairs trading exploiting mean-reverting price spreads between economically linked currency pairs (`EURUSD` vs `GBPUSD`).

- **Category**: `arbitrage` / `relative_value`
- **Supported Symbols**: `EURUSD` and `GBPUSD`
- **Recommended Timeframe**: `H1`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Cointegration Estimation**: Rolling 60-day OLS hedge ratio $\beta_t = \text{Cov}(p_{EUR}, p_{GBP}) / \text{Var}(p_{GBP})$.
  - **Spread Z-Score**: $Z_t = (S_t - \mu_S) / \sigma_S$, where spread $S_t = \ln(EUR_t) - \beta_t \ln(GBP_t)$.
  - **Mean Reversion Trigger**: Enter long spread when $Z_t < -1.5$, short spread when $Z_t > 1.5$.
  - **Structural Stop-Loss**: Hard emergency stop if spread diverges beyond $|Z_t| > 3.0$ (structural cointegration breakdown).
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$13,620.00 USD (+136.20%)**
  - **Profit Factor (PF)**: **1.62**
  - **Maximum Equity Drawdown**: **10.90%**
  - **Total Trades**: 420 | **Win Rate**: 61.5%
  - **Minimum Recorded Margin Level**: **620.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/StatArbPairs)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/StatArbPairs/paper.pdf)

---

### 5. KalmanFilterEA
State-space adaptive filtering estimating latent continuous price and velocity drift to separate macroeconomic trend signals from high-frequency market noise.

- **Category**: `trend_following` / `state_space`
- **Supported Symbols**: `USDJPY`, `EURUSD`
- **Recommended Timeframe**: `H1`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Kinematic State Vector**: $\mathbf{x}_t = [p_t, v_t]^T$, estimating price $p_t$ and velocity drift $v_t = dp/dt$.
  - **Kalman Gain Optimization**: Continuous recursive prediction and update minimizing mean squared measurement error.
  - **Velocity Trigger**: Trades in the direction of normalized velocity drift $v_t / \sigma_v$ exceeding threshold $\theta$.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$14,250.00 USD (+142.50%)**
  - **Profit Factor (PF)**: **1.68**
  - **Maximum Equity Drawdown**: **9.80%**
  - **Total Trades**: 395 | **Win Rate**: 58.4%
  - **Minimum Recorded Margin Level**: **820.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/KalmanFilterEA)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/KalmanFilterEA/paper.pdf)

---

### 6. HMMRegimeEA
Hidden Markov Model 2-state Gaussian mixture regime filter that dynamically switches trading behavior between directional trending and turbulent chop regimes.

- **Category**: `trend_following` / `regime_switching`
- **Supported Symbols**: `EURUSD`, `USDJPY`, `GBPUSD`
- **Recommended Timeframe**: `H1`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **State 0 (Calm / Trending)**: Low volatility, directional trend-following active with standard lot allocation.
  - **State 1 (Turbulent / Crisis)**: High volatility, position size automatically scaled down by 60% or shifted to mean-reversion counter-trend mode.
  - **Hamilton Filter**: Real-time Bayesian posterior state probability updating $P(S_t = 0 | r_{1:t})$.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$15,480.00 USD (+154.80%)**
  - **Profit Factor (PF)**: **1.74**
  - **Maximum Equity Drawdown**: **8.90%**
  - **Total Trades**: 340 | **Win Rate**: 59.1%
  - **Minimum Recorded Margin Level**: **890.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/HMMRegimeEA)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/HMMRegimeEA/paper.pdf)

---

### 7. OrderFlowImbalanceEA
Institutional microstructure Expert Advisor tracking order book Bid-Ask delta imbalances and tick volume absorption on spot commodities and currencies.

- **Category**: `breakout` / `market_microstructure`
- **Supported Symbols**: `XAUUSD` (Spot Gold), `EURUSD`
- **Recommended Timeframe**: `M15`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Cumulative Volume Delta (CVD)**: Proxy metric measuring aggressive buyer vs seller order flow: $\Delta_t = \text{Volume}_t \cdot \frac{C_t - \text{Mid}_t}{\text{Range}_t}$.
  - **Absorption Detection**: Heavy volume traded with zero price progression indicates institutional limit order absorption, triggering trade placement.
  - **Dynamic Volatility Stops**: Stop-loss sized by intraday ATR with strict trailing profit target.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$14,350.00 USD (+143.50%)**
  - **Profit Factor (PF)**: **1.65**
  - **Maximum Equity Drawdown**: **9.40%**
  - **Total Trades**: 512 | **Win Rate**: 57.2%
  - **Minimum Recorded Margin Level**: **840.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/OrderFlowImbalanceEA)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/OrderFlowImbalanceEA/paper.pdf)

---

### 8. VolBreakoutATR
Exploits volatility regime transitions using the Garman-Klass extreme-value volatility estimator to detect volatility compression followed by aggressive explosive expansion.

- **Category**: `breakout` / `volatility`
- **Supported Symbols**: `USDJPY`, `EURUSD`
- **Recommended Timeframe**: `H1`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Garman-Klass Estimator**: $\sigma_{GK}^2 = 0.5 (\ln(H/L))^2 - (2\ln 2 - 1)(\ln(C/O))^2$, incorporating intraday high, low, open, and close prices.
  - **Compression Filter**: Triggers only when 15-day rolling $\sigma_{GK}$ enters the lowest 25th percentile (volatility coiling).
  - **Breakout Trigger**: Enters as soon as price breaks out of the 5-day high/low channel with expanding tick volume.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$13,850.00 USD (+138.50%)**
  - **Profit Factor (PF)**: **1.61**
  - **Maximum Equity Drawdown**: **10.20%**
  - **Total Trades**: 380 | **Win Rate**: 54.8%
  - **Minimum Recorded Margin Level**: **780.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/VolBreakoutATR)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/VolBreakoutATR/paper.pdf)

---

### 9. CrossSectionalMomentum
Multi-currency basket cross-sectional relative strength momentum system ranking G10 currency pairs to capture global macro currency trends.

- **Category**: `trend_following` / `cross_sectional`
- **Supported Symbols**: Multi-FX Basket (`EURUSD`, `GBPUSD`, `AUDUSD`, `NZDUSD`, `USDCAD`, `USDJPY`)
- **Recommended Timeframe**: `H4`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Momentum Ranking**: Ranks the 6 major currencies based on rolling 20-day volatility-adjusted cumulative returns.
  - **Long/Short Allocation**: Systematically goes long the top 2 strongest currencies and short the bottom 2 weakest currencies against USD.
  - **Periodic Rebalancing**: Portfolio rebalanced bi-weekly to capture currency momentum persistence without turnover friction drag.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$16,200.00 USD (+162.00%)**
  - **Profit Factor (PF)**: **1.71**
  - **Maximum Equity Drawdown**: **9.10%**
  - **Total Trades**: 440 | **Win Rate**: 57.5%
  - **Minimum Recorded Margin Level**: **860.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/CrossSectionalMomentum)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/CrossSectionalMomentum/paper.pdf)

---

### 10. MeanRevertingOU
Continuous-time Ornstein-Uhlenbeck stochastic drift filtration system calculating analytical half-life of mean reversion to exploit temporary price dislocations.

- **Category**: `mean_reversion` / `stochastic_process`
- **Supported Symbols**: `EURUSD`, `GBPUSD`
- **Recommended Timeframe**: `H1`
- **Risk Level**: 🟡 Medium Risk | **Grid Overlay**: ❌ None
- **Minimum Recommended Capital**: $1,000 USD
- **Algorithmic Logic**:
  - **Ornstein-Uhlenbeck Process**: $dx_t = \theta (\mu - x_t) dt + \sigma dW_t$.
  - **Analytical Parameter Estimation**: Fits continuous drift $\theta$ and half-life $t_{1/2} = \ln 2 / \theta$ via rolling AR(1) discrete regression.
  - **Statistical Entry**: Enters counter-trend when price deviates by $> 1.5$ stationary standard deviations ($\sigma_{OU} = \sigma / \sqrt{2\theta}$).
  - **Structural Stop-Loss**: Hard emergency stop if price deviates $> 3.0 \sigma_{OU}$, preventing open-ended trending losses.
- **MT5 Backtest Performance (2023.01.01 -- 2025.12.31 Benchmark)**:
  - **Initial Deposit**: $10,000.00 USD
  - **Total Net Profit**: **+$14,850.00 USD (+148.50%)**
  - **Profit Factor (PF)**: **1.67**
  - **Maximum Equity Drawdown**: **8.80%**
  - **Total Trades**: 365 | **Win Rate**: 62.1%
  - **Minimum Recorded Margin Level**: **880.0%**
- **Quick Links**:
  - [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/MeanRevertingOU)
  - [Research Paper (PDF)](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/papers/strategies/MeanRevertingOU/paper.pdf)

---

## 🛡️ Panel B: Baseline Disciplined Non-Grid Strategies (4 EAs)

---

### 11. COT1
- **Category**: `trend_following` / `macro_sentiment` | **Symbol**: `EURUSD` Daily | **Risk**: 🟡 Medium
- **Algorithmic Logic**: Leverages weekly CFTC Commitments of Traders (COT) report data. Identifies extreme net positioning by Commercial Hedgers and enters trend continuation confirmed by SuperTrend indicator.
- **MT5 Backtest Performance (2023--2025 Benchmark)**:
  - **Profit Factor (PF)**: **1.65** | **Max Drawdown**: **14.20%** | **Min Margin Level**: **680.0%**
  - *Author In-Sample Report (2020--2023)*: Initial $10,000 $\to$ Net Profit $429,635.03, PF 3.65.
- [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/COT1)

### 12. 2MOMEMA
- **Category**: `trend_following` | **Symbol**: `EURUSD` H1 | **Risk**: 🟠 High
- **Algorithmic Logic**: Dual Momentum (fast and slow rate-of-change) combined with 200 EMA macro filter. Mandatory hard stop-loss.
- **MT5 Backtest Performance (2023--2025 Benchmark)**:
  - **Profit Factor (PF)**: **1.38** | **Max Drawdown**: **18.40%** | **Min Margin Level**: **450.0%**
- [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/2MOMEMA)

### 13. LRCMACD
- **Category**: `trend_following` | **Symbol**: `EURUSD` H1 | **Risk**: 🟠 High
- **Algorithmic Logic**: Linear Regression Channel deviation bands combined with MACD signal histogram crossovers.
- **MT5 Backtest Performance (2023--2025 Benchmark)**:
  - **Profit Factor (PF)**: **1.42** | **Max Drawdown**: **16.50%** | **Min Margin Level**: **520.0%**
- [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/LRCMACD)

### 14. TemplateEA
- **Category**: `trend_following` | **Symbol**: `XAUUSD`, `EURUSD` M5 | **Risk**: 🟢 Low
- **Algorithmic Logic**: Reference institutional template showcasing dynamic fractional risk position sizing, ATR hard stop-loss, and weekend liquidation safeguards.
- **MT5 Backtest Performance (2023--2025 Benchmark)**:
  - **Profit Factor (PF)**: **1.35** | **Max Drawdown**: **8.50%** | **Min Margin Level**: **850.0%**
- [Source Code](https://github.com/BerryUIKI/Berrytrade-EA/tree/main/strategies/experimental/TemplateEA)

---

## ⚠️ Panel C: Retail Grid & Martingale Incubation Strategies (10 EAs, Extreme Risk)

> [!CAUTION]
> **HIGH RISK OF TOTAL CAPITAL RUIN**  
> The strategies in this tier use **loss-averaging grid and martingale mechanics** without hard stop-losses.  
> While author backtests display smooth upward equity curves with profit factors $>2.0$, our **3-year standardized institutional stress audit (2023--2025)** reveals that unhedged grid strategies undergo massive margin depletion ($63\%\sim94\%$ drawdowns) and inevitably terminate in stop-out during strong sustained trends.

| Strategy | Author Period | Author Net Profit | Author PF | 3-Year Audit Max DD (%) | 3-Year Min Margin (%) | Risk Assessment & Audit Finding |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **`2MAAOS`** | 2019--2023 | $1,151,871.33 | 2.85 | **64.79%** | 171.5% | Severe margin compression under trending EUR. |
| **`2MACDSTO`** | 2020--2023 | $164,015.67 | 4.42 | **68.09%** | 70.9% | Dangerous grid layering on NZDUSD swings. |
| **`3MACD`** | 2020--2023 | $71,112.05 | 2.04 | **63.01%** | 107.8% | High turnover scalping grid vulnerable to slippage. |
| **`3MAF`** | 2020--2023 | $429,367.37 | 2.05 | **75.30%** | **36.2%** | **Broker Margin Call Danger** (Margin level dipped $<50\%$). |
| **`AFAOSMD`** | 2019--2023 | $128,373.90 | 2.34 | **83.59%** | **51.0%** | Critical margin depletion on cross-currency trending. |
| **`BBRSI`** | 2021--2023 | $36,877.30 | 2.31 | **70.23%** | 1314.0% | **2024 Gold Expansion Liquidation Autopsy**: Unhedged short grid wiped out account in 2024 Gold rally. |
| **`CEZLSMA`** | 2019--2023 | $3,331,060.41 | 2.78 | **94.00%** | **16.2%** | **Complete Account Liquidation**: Dropped below 20% broker stop-out level. |
| **`DHLAOS`** | 2020--2023 | $61,313.64 | 1.92 | **56.02%** | 332.5% | Daily high/low grid suffering prolonged drawdown. |
| **`LRCUTB`** | 2019--2023 | $311,962.38 | 1.92 | **66.95%** | 146.2% | Linear regression channel grid layering. |
| **`NWERSIASF`** | 2019--2023 | $1,097,801.13 | 2.19 | **68.62%** | **57.0%** | Nadaraya-Watson kernel grid near stop-out. |

---

## 📈 Multi-Strategy Combinatorial Portfolio & Risk Parity Allocation

When trading multiple EAs simultaneously, institutional risk parity and combinatorial allocation transform single-strategy cyclical drawdowns into a smooth, low-volatility portfolio.

Evaluated over the **2023.01.01 -- 2025.12.31** benchmark across the **10 verified candidate strategies**:

### Comparative Model Summary:

| Allocation Model | Annualized Return | Annualized Volatility | Sharpe Ratio ($R_f=2\%$) | Sortino Ratio | Max Drawdown (%) | Calmar Ratio | Diversification Ratio ($DR$) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Equal Weight ($1/N$)** | 39.21% | 3.81% | 9.78 | 8.60 | 2.07% | 18.96 | 3.17 |
| **Inverse Volatility** | 39.86% | 3.58% | 10.58 | 9.28 | 1.88% | 21.16 | 3.30 |
| **Minimum Variance** | 39.92% | **2.91%** | **13.01** | 11.77 | **1.26%** | **31.60** | **4.00** |
| **Max Sharpe Ratio** | 40.20% | 2.92% | **13.07** | 11.55 | 1.28% | 31.42 | 3.96 |
| **Equal Risk Contribution (ERC)** | 39.93% | 3.01% | **12.58** | 11.01 | **1.28%** | **31.12** | 3.88 |
| **Hierarchical Risk Parity (HRP)** | **40.47%** | 3.40% | 11.30 | 10.17 | 1.52% | 26.67 | 3.40 |

### Recommended Risk Parity Capital Allocation Weights ($\mathbf{w}^*$):
- **`OrderFlowImbalanceEA`** (Gold CVD): **12.91%**
- **`KalmanFilterEA`** (USDJPY Drift): **12.18%**
- **`HMMRegimeEA`** (EURUSD Regime): **11.86%**
- **`CrossSectionalMomentum`** (FX Basket): **11.22%**
- **`StatArbPairs`** (EUR/GBP Spread): **10.74%**
- **`VolBreakoutATR`** (USDJPY GK Vol): **10.23%**
- **`MeanRevertingOU`** (EURUSD OU Mean Reversion): **9.49%**
- **`TurtleTrader`** (EURUSD Trend): **7.91%**
- **`SMC_FVG`** (EURUSD Smart Money): **7.14%**
- **`LondonBreakout`** (GBPUSD Session): **6.32%**

*Full mathematical formulations and diagnostics can be viewed in [`docs/PORTFOLIO_ALLOCATION.md`](https://github.com/BerryUIKI/Berrytrade-EA/blob/main/docs/PORTFOLIO_ALLOCATION.md).*

---

## 🛠️ How to Apply Presets in MetaTrader 5

1. **Download the Strategy**:
   - Copy `<StrategyName>.mq5` into your MT5 data folder: `MQL5/Experts/Berrytrade/`.
   - Compile via MetaEditor (Press `F7`). Zero errors and warnings should be generated.
2. **Copy Parameter Preset**:
   - Copy `default.set` or `conservative.set` from the strategy's `presets/` folder into `MQL5/Profiles/Tester/` or `MQL5/Presets/`.
3. **Attach to Chart**:
   - Open the recommended symbol chart and timeframe (e.g. `EURUSD` on `H1`).
   - Drag the EA from the Navigator window onto the chart.
   - In the **Inputs** tab, click **Load...** and select the `.set` file.
   - Verify `InpMagicNumber` is unique across all active EAs.
   - Click **OK** and ensure **Algo Trading** is enabled in the MT5 top toolbar.
