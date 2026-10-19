# Berrytrade-EA Technical Architecture

> **Audience**: Quant developers, MQL5 engineers, and algorithmic traders contributing to Berrytrade-EA.  
> **Language**: English (Developer documentation is exclusively maintained in English).

---

## 1. Core Engineering Principles

Traditional MQL5 repositories often suffer from three critical anti-patterns:
1. **Monolithic Dumping**: Dozens of `.mq5` files placed in a single `Experts/` folder without explicit parameter presets or backtesting data.
2. **Scattered Dependencies**: Strategy code in `Experts/`, required indicators in `Indicators/`, test results in `Test/`, and compiled binaries in `Build/`. Removing or updating one strategy risks breaking others.
3. **Lack of Automated Governance**: No machine-readable metadata, no risk tiering, and no automated validation of safety or reproducibility.

**Berrytrade-EA** adopts a **Modular Strategy Package** architecture:
- **Self-Contained Strategies**: Each EA lives in its own directory with its source code, parameter presets (`.set`), backtest reports, and structured metadata.
- **Strict Risk Classification**: All EAs are categorized by risk profile (e.g., Trend, Mean Reversion, Grid, High-Frequency Scalping). Dangerous patterns (e.g., Martingale) are quarantined or rejected.
- **Two-Tier Quality Funnel**: New community contributions enter `strategies/experimental/`. Only strategies that pass rigorous benchmark backtesting, stress testing, and code review advance to `strategies/verified/`.
- **Zero Committed Binaries**: No `.ex5` files are stored in git. All compilations are performed locally or in CI pipelines.

---

## 2. Directory Layout

```text
Berrytrade-EA/
├── .github/                       # GitHub workflows, Issue & PR templates
│   ├── ISSUE_TEMPLATE/            # Standardized submission & bug templates
│   ├── PULL_REQUEST_TEMPLATE/     # Comprehensive PR checklist for EA submissions
│   └── workflows/                 # CI/CD pipelines (validation, wiki sync)
├── docs/                          # Developer Technical Documentation (English only)
│   └── developer/
│       ├── architecture.md
│       ├── contribution-guidelines.md
│       ├── ea-ingestion-specification.md
│       └── benchmarking-standards.md
├── wiki/                          # User-Facing Documentation (Multi-Language, Wiki-Ready)
│   ├── Home.md / Home.zh-CN.md
│   ├── Getting-Started.md / Getting-Started.zh-CN.md
│   ├── Risk-Management.md / Risk-Management.zh-CN.md
│   ├── Strategy-Catalog.md / Strategy-Catalog.zh-CN.md
│   └── Troubleshooting-and-FAQ.md / Troubleshooting-and-FAQ.zh-CN.md
├── strategies/                    # Self-contained EA packages
│   ├── verified/                  # Production-grade, benchmarked strategies
│   └── experimental/              # Community contributions & research incubators
│       └── <StrategyName>/
│           ├── src/               # EA source code (.mq5)
│           ├── presets/           # MT5 .set parameter presets
│           ├── reports/           # HTML / JSON / equity curve reports
│           ├── metadata.json      # Machine-readable specification
│           └── README.md          # Strategy documentation
├── shared/                        # Shared libraries and reusable components
│   ├── Include/Berrytrade/        # Namespaced core utilities
│   ├── Indicators/                # Shared custom technical indicators
│   └── Scripts/                   # Helper scripts
├── benchmarks/                    # Standardized testing environments & datasets
│   ├── standards.json             # Baseline broker constraints (spread, slippage, capital)
│   └── README.md                  # Benchmark methodology
├── tools/                         # Operational & CI toolchain
│   ├── validate_ea.py             # Linter & metadata validator
│   ├── generate_catalog.py        # Automated README catalog generator
│   ├── sync_to_mt5.ps1            # Sync / symlink repo into MT5 terminal
│   └── publish_wiki.ps1           # Publish wiki/ to GitHub Wiki repository
├── .gitignore                     # Ignoring binaries, logs, and sensitive data
├── CONTRIBUTING.md                # Entry point for contributors
├── LICENSE                        # MIT License
├── README.md                      # Primary English project homepage
└── README.zh-CN.md                # Chinese project homepage
```

---

## 3. Strategy Package Specification

Every directory under `strategies/{verified|experimental}/<StrategyName>` must follow this layout:

| Item | Path | Mandatory | Description |
| :--- | :--- | :---: | :--- |
| **Source** | `src/<StrategyName>.mq5` | **Yes** | Clean, well-commented MQL5 source code. |
| **Metadata** | `metadata.json` | **Yes** | Strategy parameters, author, symbols, timeframe, risk score. |
| **Documentation** | `README.md` | **Yes** | Detailed logic, edge cases, entry/exit rules, and risk warnings. |
| **Presets** | `presets/*.set` | **Yes** | At least one valid MetaTrader 5 `.set` preset for backtesting. |
| **Reports** | `reports/` | **Yes** | MT5 Strategy Tester report summary (`summary.json`) or HTML report. |

---

## 4. MetaTrader 5 Integration

Since MetaTrader 5 expects files inside `MQL5/Experts`, `MQL5/Include`, and `MQL5/Indicators`, a sync utility is provided:
- Run `powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<MT5_DATA_PATH>"` to create symbolic links or mirror the repository structure directly into your MT5 terminal without corrupting the modular Git repository layout.
