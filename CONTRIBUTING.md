# Contributing to Berrytrade-EA

Welcome! We are excited to build a transparent, institutional-grade, open-source repository for automated trading strategies (EAs) in MetaTrader 5.

---

### Language Guidelines (语言指引)
- **Primary Language**: English is used for all Pull Requests, Code Reviews, Issues, and MQL5 code comments.
- **Secondary Language**: Chinese (中文) is fully supported in documentation under `docs/zh-CN/` and `README.zh-CN.md`.

---

### Quick Links
- **[Contribution Guidelines (English)](docs/en/contribution-guidelines.md)**
- **[贡献者指南 (中文)](docs/zh-CN/contribution-guidelines.md)**
- **[EA Ingestion & Review Specification (English)](docs/en/ea-ingestion-specification.md)**
- **[EA 入库与审核标准规范 (中文)](docs/zh-CN/ea-ingestion-specification.md)**
- **[Architecture & Layout (English)](docs/en/architecture.md)**
- **[架构与工程规范 (中文)](docs/zh-CN/architecture.md)**

---

### In a Nutshell: How to Submit an EA
1. Check out a branch `feat/ea-<strategy-name>`.
2. Place your EA in `strategies/experimental/<strategy-name>/` with:
   - `src/<strategy-name>.mq5`
   - `presets/*.set`
   - `reports/summary.json`
   - `metadata.json`
   - `README.md`
3. Run local validation: `python tools/validate_ea.py --path strategies/experimental/<strategy-name>`
4. Submit a Pull Request targeting `main` using our PR template.
