# 🤖 Berrytrade-EA

<p align="center">
  <strong>Institutional-Grade Open-Source Expert Advisors (EAs) & Quantitative Backtesting Framework for MetaTrader 5 (MQL5)</strong>
</p>

<p align="center">
  <a href="README.md"><strong>English</strong></a> | 
  <a href="README.zh-CN.md"><strong>简体中文</strong></a> | 
  <a href="wiki/Home.md"><strong>User Wiki</strong></a> |
  <a href="AGENTS.md"><strong>AI Agent Guidelines</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-MQL5-blue.svg" alt="MQL5">
  <img src="https://img.shields.io/badge/Platform-MetaTrader%205-orange.svg" alt="MetaTrader 5">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/Branching-GitFlow-blueviolet.svg" alt="GitFlow">
  <img src="https://img.shields.io/badge/CI-Automated%20Audit-success.svg" alt="CI Audit">
</p>

---

## 📖 Overview

**Berrytrade-EA** is an open-source initiative dedicated to engineering high-quality, transparent, and reproducible algorithmic trading strategies (Expert Advisors) for **MetaTrader 5 (MT5)**.

Unlike traditional repositories that accumulate uncurated `.mq5` files without parameters or risk audits, **Berrytrade-EA** enforces:
- **Modular Packaging**: Every EA is a self-contained unit with source code, `.set` parameter presets, backtest reports, and structured metadata.
- **Strict Risk Governance**: Mandatory hard Stop-Loss enforcement. High-risk mechanics (such as Martingale or Uncapped Grid) are strictly quarantined and flagged.
- **Two-Tier Quality Funnel**: Community submissions enter `experimental/` for incubation, and graduate to `verified/` after passing standardized multi-year benchmark audits.
- **Automated Security CI**: Automated scanning prevents malicious Win32 DLL calls, telemetry backdoors, and broken schemas.
- **Academic Research Integration**: Every strategy is backed by a quantitative research paper (PDF) authored by **Berry Wahlberg** (`Berrytrade Quantitative Research`) with Nature/Science-style diagnostic figures and full BibTeX bibliographies.

---

## 📚 Documentation System

We maintain a strict separation between technical, agentic, and user-facing documentation:

| Category | Target Audience | Language | Location |
| :--- | :--- | :---: | :--- |
| **AI Agent Governance** | Autonomous AI pair-programmers & dev agents | **English Only** | [**`AGENTS.md`**](AGENTS.md) |
| **Developer Technical Docs** | Quant researchers, MQL5 developers, contributors | **English Only** | [`docs/developer/`](docs/developer/) |
| **Research Papers** | Academic readers, quant allocators | **LaTeX / English Research Paper (PDF)** | [`papers/`](papers/) |
| **User Wiki & Trader Guides** | Traders, end-users, operators | **Multi-Language (EN / 中文)** | [`wiki/`](wiki/) & GitHub Wiki |

- 🤖 **Agent Governance**: [AI Agent Guidelines](AGENTS.md) &bull; [Agent Specs](docs/developer/agents.md)
- 🛠️ **Developer Docs**: [Architecture](docs/developer/architecture.md) &bull; [EA Ingestion Spec](docs/developer/ea-ingestion-specification.md) &bull; [Contribution Guidelines](docs/developer/contribution-guidelines.md) &bull; [Benchmarking Standards](docs/developer/benchmarking-standards.md)
- 📑 **Research Papers**: [Master Synthesis Paper](papers/synthesis/main.pdf) &bull; [14 Strategy Monograph Index](papers/README.md)
- 📖 **User Wiki**: [Getting Started](wiki/Getting-Started.md) ([中文](wiki/Getting-Started-zh.md)) &bull; [Risk Management](wiki/Risk-Management.md) ([中文](wiki/Risk-Management-zh.md)) &bull; [Strategy Catalog](wiki/Strategy-Catalog.md) ([中文](wiki/Strategy-Catalog-zh.md)) &bull; [FAQ](wiki/Troubleshooting-and-FAQ.md) ([中文](wiki/Troubleshooting-and-FAQ-zh.md))

---

## 📑 Quantitative Research Papers (PDF)

All strategies undergo continuous 3-year execution-constrained backtesting (`2023.01.01 -- 2025.12.31`) with 120ms simulated latency, floating spreads, and $7/lot commissions. Publications are signed by **Berry Wahlberg** (`Berrytrade Quantitative Research`):

- 🏛️ **Master Synthesis Paper**: [*The Anatomy of Grid Overlays and the Illusion of Alpha: An Empirical Case Study of Retail Expert Advisors on MetaTrader 5*](papers/synthesis/main.pdf) ([LaTeX Source](papers/synthesis/main.tex))
- 📊 **Individual Strategy Research Monograph Index**: Complete set of 14 standalone papers with 6 diagnostic figures and verified BibTeX references are indexed in [**`papers/README.md`**](papers/README.md).

---

## 📊 Strategy Catalog

The catalog below is dynamically generated from strategy `metadata.json` files:

### Verified Strategies (Production-Grade)

*Strict criteria: Max equity drawdown $\le 20\%$, mandatory hard stop-loss, zero unhedged grid/martingale, Calmar ratio $\ge 1.5$.*

> **Benchmark Leader in Review for Graduation**:
> - **[`COT1`](strategies/experimental/COT1)**: **14.20% Max Drawdown**, **1.65 Profit Factor**, **+$28,450 Net Profit**, **680.0% Min Margin Level**, strictly single-order execution with CFTC institutional macro positioning and SuperTrend trailing.

### Experimental Strategies (Incubator & Community)

| Strategy | Category | Risk Level | Symbols | TF | Min Cap | Summary |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| [COT1](strategies/experimental/COT1) | `trend_following` | **Medium** | EURUSD | Daily | $1,000 | Commitments of Traders (COT) report sentiment with SuperTrend indicator (Verified Benchmark Leader). |
| [TurtleTrader](strategies/experimental/TurtleTrader) | `trend_following` | **Medium** | EURUSD, XAUUSD, GBPUSD | Daily | $1,000 | Classic Turtle Trading System: Donchian Breakout with N-ATR Volatility Sizing, 2N Hard Stop Loss, and Dynamic Pyramiding. |
| [LondonBreakout](strategies/experimental/LondonBreakout) | `breakout` | **Medium** | GBPUSD, EURUSD, EURGBP | M15 | $1,000 | Institutional London Opening Breakout: Asian Session Consolidation Range Liquidity Expansion with Zero Overnight Carryover. |
| [SMC_FVG](strategies/experimental/SMC_FVG) | `breakout` | **Medium** | EURUSD, GBPUSD, XAUUSD | H1 | $1,000 | Smart Money Concepts (SMC) Fair Value Gap (FVG): Price Delivery Imbalance Mitigation with Consequent Encroachment & Hard Stop Loss. |
| [StatArbPairs](strategies/experimental/StatArbPairs) | `arbitrage` | **Medium** | EURUSD, GBPUSD, AUDUSD | H1 | $1,000 | Cointegrated Statistical Arbitrage Pairs Trading: Dynamic OLS Beta Hedge Ratio, Z-Score Spread Mean Reversion & Structural Divergence Stop Loss. |
| [KalmanFilterEA](strategies/experimental/KalmanFilterEA) | `trend_following` | **Medium** | EURUSD, USDJPY, XAUUSD | H1 | $1,000 | State-Space Adaptive Kalman Filter: Continuous 2D Kinematic Price Drift Velocity Estimation, Dynamic Fractional Risk & Hard Stop Loss. |
| [LRCMACD](strategies/experimental/LRCMACD) | `trend_following` | **High** | EURUSD | H1 | $1,000 | Linear Regression Channel and MACD trend strategy (Disciplined, no grid). |
| [2MOMEMA](strategies/experimental/2MOMEMA) | `trend_following` | **High** | EURUSD | H1 | $1,000 | Dual Momentum and EMA trend filter strategy (Disciplined, no grid). |
| [TemplateEA](strategies/experimental/TemplateEA) | `trend_following` | **Low** | XAUUSD, EURUSD | M5 | $1,000 | Standardized MQL5 EA template showcasing risk management, hard stop-loss, and modular structure. |
| [BBRSI](strategies/experimental/BBRSI) | `mean_reversion` | **High** | XAUUSD | M5 | $1,000 | Bollinger Bands and RSI mean reversion strategy (supports controlled non-grid mode). |
| [2MAAOS](strategies/experimental/2MAAOS) | `trend_following` | **Extreme** | EURUSD, EURCAD, USDCAD | H4 | $10,000 | Dual Moving Averages and Andean Oscillator with Grid overlay. |
| [2MACDSTO](strategies/experimental/2MACDSTO) | `mean_reversion` | **Extreme** | NZDUSD | H3 | $10,000 | Dual MACDs and Stochastic Oscillator with Grid overlay. |
| [3MACD](strategies/experimental/3MACD) | `scalping` | **Extreme** | AUDUSD | M5 | $10,000 | Triple MACD scalping strategy with Grid overlay. |
| [3MAF](strategies/experimental/3MAF) | `trend_following` | **Extreme** | USDCAD | M15 | $10,000 | Three Moving Averages and Williams Fractals with Grid overlay. |
| [AFAOSMD](strategies/experimental/AFAOSMD) | `trend_following` | **Extreme** | NZDCAD | M30 | $10,000 | Average Force, Andean Oscillator, and MACD with Grid overlay. |
| [CEZLSMA](strategies/experimental/CEZLSMA) | `trend_following` | **Extreme** | AUDUSD | M15 | $10,000 | Chandelier Exit and Zero Lag SMA (ZLSMA) with Grid overlay (94% DD, 16% margin). |
| [DHLAOS](strategies/experimental/DHLAOS) | `scalping` | **Extreme** | AUDUSD | M5 | $10,000 | Daily High/Low and Andean Oscillator scalping with Grid overlay. |
| [LRCUTB](strategies/experimental/LRCUTB) | `trend_following` | **Extreme** | AUDCAD | M15 | $10,000 | Linear Regression Candles and UT Bot alerts with Grid overlay. |
| [NWERSIASF](strategies/experimental/NWERSIASF) | `mean_reversion` | **Extreme** | USDCAD, AUDUSD, EURCHF | H2 | $10,000 | Nadaraya-Watson Envelope, RSI, and ATR Stop Loss Finder with Grid overlay. |

---

## 🚀 Open-Source Quantitative Ingestion Roadmap (Phase 2)

We are actively searching and ingesting notable open-source quantitative strategies from GitHub, MQL5 CodeBase, and academic research:

1. **`TurtleTrader`** (Classic Richard Dennis & William Eckhardt Donchian Breakout, N-volatility lot sizing, 2N trailing stop) &mdash; **[COMPLETED]**
2. **`LondonBreakout`** (Asian Session Range Liquidity Breakout, London Open, Zero Overnight Carryover) &mdash; **[COMPLETED]**
3. **`SMC_FVG`** (Smart Money Concepts / ICT Fair Value Gap, Liquidity Pools & Order Blocks) &mdash; **[COMPLETED]**
4. **`StatArbPairs`** (Cointegrated Statistical Arbitrage Pairs Trading on Major Forex) &mdash; **[COMPLETED]**
5. **`KalmanFilterEA`** (State-Space Dynamic Filtering & Adaptive Price Drift Estimation) &mdash; **[COMPLETED]**
6. **`HMMRegimeEA`** (Hidden Markov Model Gaussian Mixture Volatility Regime Switching Filter) &mdash; **[<== ACTIVE INGESTION]**

---

## 🔀 GitFlow Branching Model & Development Standards

All development and automated agent contributions adhere to strict GitFlow governance:

- **`main`**: Production-ready code and official releases. No direct commits allowed.
- **`develop`**: Primary integration branch for tested strategies and documentation.
- **`feature/<name>`**: Feature branches (e.g., `feature/ea-turtle-trader`, `feature/docs-update`).
- **Commit Cadence**: Small, atomic Pull Requests with frequent commits ("小步PR，频繁commit") following Conventional Commits (`feat`, `test`, `docs`, `fix`, `ci`).

---

## 🏗️ Repository Layout

```text
Berrytrade-EA/
├── .github/                       # GitHub workflows, Issue & PR templates
├── AGENTS.md                      # AI Agent governance & pair-programming specification
├── docs/developer/                # Developer Technical Documentation (English only)
│   ├── architecture.md
│   ├── agents.md
│   ├── benchmarking-standards.md
│   ├── contribution-guidelines.md
│   └── ea-ingestion-specification.md
├── wiki/                          # User-Facing Documentation (Multi-Language, Wiki-ready)
├── papers/                        # Academic Research Papers (PDF) (Berry Wahlberg)
│   ├── synthesis/                 # Master synthesis paper & figures
│   └── strategies/<Strategy>/     # Standalone strategy monographs & .bbl
├── strategies/                    # Self-contained EA packages
│   ├── verified/                  # Audited & benchmarked strategies (Max DD <= 20%)
│   └── experimental/              # Community submissions & research models
│       └── <StrategyName>/
│           ├── src/               # EA source code (.mq5)
│           ├── presets/           # MT5 .set parameter presets
│           ├── reports/           # Backtest summary & tester reports
│           ├── metadata.json      # Machine-readable specification
│           └── README.md          # Strategy documentation
├── shared/                        # Shared libraries and reusable headers
│   ├── Include/                   # Standardized helper classes & indicators
│   └── Indicators/                # Custom indicators
├── benchmarks/                    # Standardized testing environments & datasets
│   └── standards.json             # Baseline broker constraints (spreads, slippage)
├── tools/                         # Dev tools, CI linters, MT5 sync, Wiki publisher
│   ├── validate_ea.py             # Linter & metadata validator
│   ├── generate_catalog.py        # Automated README catalog generator
│   ├── generate_paper_figures.py  # 300 DPI Nature-style diagnostic figure generator
│   ├── build_deep_research_papers.py # Multi-pass LaTeX + BibTeX compiler
│   ├── sync_to_mt5.ps1            # Sync / symlink repo into MT5 terminal
│   └── publish_wiki.ps1           # Sync local wiki/ to GitHub Wiki
├── CONTRIBUTING.md                # Contributor guide entry point
├── LICENSE                        # MIT License
└── README.md                      # Primary project homepage
```

---

## 🚀 Quick Start: Deploying to MetaTrader 5

To install Berrytrade strategies and shared libraries into your local MT5 Terminal:

```powershell
# Run the deployment sync script
powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<YOUR_MT5_DATA_PATH>"
```

*Note: Your MT5 Data Directory can be found inside MetaTrader 5 by selecting **File -> Open Data Folder**.*

---

## 🚨 Risk Disclaimer

**USE AT YOUR OWN RISK:** Trading financial instruments, forex, metals, and CFDs carries a high level of risk and may not be suitable for all investors. Leverage can work against you as well as for you.

- **Not Financial Advice**: The contents, strategies, indicators, and software in this repository are for educational, research, and algorithmic development purposes only. None of the content constitutes investment advice.
- **No Guarantees**: Past performance, backtest simulations, and historical data do not guarantee future trading results.
- **No Liability**: The maintainers, authors, and contributors of this repository bear no responsibility or liability for any financial losses or damages incurred through the use of this software.