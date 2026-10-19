# Contributing to Berrytrade-EA

Welcome! We are excited to build a transparent, institutional-grade, open-source repository for automated trading strategies (EAs) in MetaTrader 5.

---

### Documentation & Language Policy
- **Developer Technical Documentation**: Exclusively maintained in **English** under [`docs/developer/`](docs/developer/).
  - All Pull Request titles, code reviews, discussions, and MQL5 code comments must be in English.
- **User-Facing Documentation & Wiki**: Fully **multi-language** under [`wiki/`](wiki/) (English and Chinese `zh-CN`, with community translations welcomed).

---

### Quick Links

#### 🛠️ For Developers & Quant Engineers (English Only)
- **[Contribution Guidelines](docs/developer/contribution-guidelines.md)**: PR workflow, MQL5 standards, commit conventions.
- **[EA Ingestion & Review Specification](docs/developer/ea-ingestion-specification.md)**: Quality tiers, metadata schema, banned APIs.
- **[Architecture & Layout](docs/developer/architecture.md)**: Repository layout, modular packages, MT5 integration.
- **[Benchmarking Standards](docs/developer/benchmarking-standards.md)**: Tester execution models, broker constraints.

#### 📖 For End-Users & Traders (Multi-Language Wiki)
- **[User Wiki (English)](wiki/Home.md)** | **[用户知识库 (中文)](wiki/Home-zh.md)**
- **[Getting Started (EN)](wiki/Getting-Started.md)** | **[新手上手指南 (中文)](wiki/Getting-Started-zh.md)**
- **[Risk Management (EN)](wiki/Risk-Management.md)** | **[资金风控守则 (中文)](wiki/Risk-Management-zh.md)**
- **[Strategy Catalog (EN)](wiki/Strategy-Catalog.md)** | **[策略选型手册 (中文)](wiki/Strategy-Catalog-zh.md)**
- **[Troubleshooting & FAQ (EN)](wiki/Troubleshooting-and-FAQ.md)** | **[常见问题排错 (中文)](wiki/Troubleshooting-and-FAQ-zh.md)**

---

### In a Nutshell: How to Submit an EA
1. Check out a branch `feat/ea-<strategy-name>`.
2. Place your EA package in `strategies/experimental/<strategy-name>/` with:
   - `src/<strategy-name>.mq5`
   - `presets/*.set`
   - `reports/summary.json`
   - `metadata.json`
   - `README.md`
3. Run local validation: `python tools/validate_ea.py --path strategies/experimental/<strategy-name>`
4. Submit a Pull Request targeting `main` using our PR template.
