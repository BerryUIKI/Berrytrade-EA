# Contribution Guidelines

Thank you for contributing to **Berrytrade-EA**! We welcome open-source contributions from quantitative traders, MQL5 developers, and researchers worldwide.

---

## 1. Primary & Secondary Languages

- **Primary Language (English)**:
  - All Pull Request titles, descriptions, and discussion threads.
  - All GitHub Issues and bug reports.
  - MQL5 code comments, function docstrings, input parameter descriptions, and log outputs.
  - Root `README.md` and primary files under `docs/en/`.
- **Secondary Language (Chinese / 中文)**:
  - Chinese documentation is located under `docs/zh-CN/` and root `README.zh-CN.md`.
  - Strategy packages may include bilingual explanations in their strategy `README.md`.
- **Future I18N Architecture**:
  - Documentation files follow parallel mirror paths: `docs/<lang>/<topic>.md`.
  - When submitting a new documentation feature or major update, English is mandatory; translated versions in Chinese or other languages are highly encouraged.

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
- `feat`: A new strategy or shared utility.
- `fix`: A bug fix or logic correction.
- `docs`: Documentation updates or translations.
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
   - Class names: `PascalCase` (e.g., `CTradeManager`).
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
3. Construct your strategy package in `strategies/experimental/<MyStrategy>/` following the [EA Ingestion Specification](file:///f:/dev/Berrytrade-EA/docs/en/ea-ingestion-specification.md):
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
7. Engage with maintainers during code review and address any feedback.
