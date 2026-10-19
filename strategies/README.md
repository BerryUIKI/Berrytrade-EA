# Strategies Directory

This directory hosts all Expert Advisors (EAs) within the Berrytrade ecosystem.

---

## Structure

- `verified/`: Rigorously backtested, low-to-medium risk, production-ready strategies.
- `experimental/`: Community submissions, prototype algorithms, and exploratory research models.

---

## Strategy Packaging Standard

Each strategy is housed in its own self-contained subfolder:
```text
strategies/{tier}/<StrategyName>/
├── src/
│   └── <StrategyName>.mq5          # Primary EA source file
├── presets/
│   └── Default_<Symbol>_<TF>.set   # Default parameter preset
├── reports/
│   ├── summary.json                # Standardized summary metrics
│   └── report.html                 # MT5 HTML report (optional)
├── metadata.json                   # Strategy metadata
└── README.md                       # Documentation
```

See [TemplateEA](experimental/TemplateEA/) for a fully compliant example package.
