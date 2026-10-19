# Developer Contribution Guidelines

> **Audience**: Quant developers, MQL5 engineers, and contributors.  
> **Language**: English (Developer technical discussions, code comments, and PRs are strictly in English).

---

## 1. Language Policy

- **Developer & Technical Documentation**: Exclusively maintained in **English**.
- **MQL5 Source Code**: All variable names, function names, docstrings, input parameter labels, and runtime logs must be in **English**.
- **Pull Requests & Code Reviews**: PR titles, descriptions, commit messages, and review conversations must be in **English**.
- **User-Facing Documentation & Wiki**: Supported in multiple languages (English, Chinese, and community translations) located under the `wiki/` directory.

---

## 2. Git Branching & Commit Conventions

### 2.1 Branch Naming
- New EA submission: `feat/ea-<strategy-name>` (e.g. `feat/ea-bollinger-rsi`)
- Core library update: `feat/shared-<feature-name>`
- Bug fix: `fix/<issue-description>`
- Documentation: `docs/<topic-name>`
- Backtest/benchmark updates: `benchmark/<strategy-name>`

### 2.2 Commit Message Format
We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
```text
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

Common types:
- `feat`: A new strategy, tool, or shared library module.
- `fix`: A bug fix or logic correction.
- `docs`: Developer documentation updates.
- `wiki`: User-facing Wiki updates or translations.
- `test`: Adding backtests, presets, or validation scripts.
- `refactor`: Code refactoring without changing trade logic.
- `ci`: CI/CD workflows and automated tool changes.

Example:
```text
feat(ea): add BBRSI trend and mean-reversion strategy

- Implemented M5 entry and exit logic using Bollinger Bands and RSI
- Added default presets for XAUUSD M5
- Included 2023-2025 backtest report and summary.json
- Validated via tools/validate_ea.py
```

---

## 3. MQL5 Coding Standards

To ensure code clarity and long-term maintainability:

1. **Input Parameters**:
   - Prefix all user-facing inputs with `Inp` (e.g., `input double InpRiskPercent = 0.5;`).
   - Include English descriptions via comments for MT5 parameter UI:
     ```mql5
     input double InpTakeProfitPoints = 200.0; // Take Profit (in Points)
     input double InpStopLossPoints   = 100.0; // Hard Stop Loss (in Points)
     ```
2. **Naming Conventions**:
   - Class names: `PascalCase` (e.g., `CTradeRiskManager`).
   - Methods & Functions: `PascalCase` (e.g., `CheckEntrySignal()`).
   - Member variables: `m_camelCase` (e.g., `m_magicNumber`).
   - Enums & Constants: `UPPER_SNAKE_CASE` or `ENUM_...`.
3. **Robust Risk Safeguards**:
   - Every EA must explicitly verify account minimum stop distance (`SYMBOL_TRADE_STOPS_LEVEL`), volume step (`SYMBOL_VOLUME_STEP`), and minimum lot limits (`SYMBOL_VOLUME_MIN`).
   - Hard Stop-Loss calculation is required upon order execution.
4. **No Direct Hardcoded Paths**:
   - Do not hardcode absolute Windows paths (e.g., `C:\Program Files\...`). Always use standard MQL5 folder abstractions (`TerminalInfoString(TERMINAL_DATA_PATH)`).

---

## 4. Submitting a Strategy PR

Follow these steps when proposing a new EA:

1. Fork the repository and clone your fork locally.
2. Create a new branch: `git checkout -b feat/ea-my-strategy`.
3. Construct your strategy package in `strategies/experimental/<MyStrategy>/` following the [EA Ingestion Specification](ea-ingestion-specification.md):
   - `src/<MyStrategy>.mq5`
   - `presets/Default_<Symbol>_<TF>.set`
   - `reports/summary.json`
   - `metadata.json`
   - `README.md`
4. Run the local validation script:
   ```powershell
   python tools/validate_ea.py --path strategies/experimental/<MyStrategy>
   ```
5. Commit and push your branch to GitHub.
6. Open a Pull Request targeting the `main` branch, selecting the **EA Submission Template**.
7. Address any feedback during peer review.
