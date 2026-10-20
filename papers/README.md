# 📑 Berrytrade Quantitative Research Papers

> **Lead Author**: Berry Wahlberg (`Berrytrade Quantitative Research, Singapore`)  
> **Contact**: `research@berrytrade.org`  
> **Format**: Academic Preprint for arXiv Quantitative Finance (`q-fin.TR` Trading & Market Microstructure, `q-fin.PM` Portfolio Management)  
> **Target Style**: Nature / Science publication graphics (300 DPI) & rigorous mathematical derivations

---

## 🏛️ Master Synthesis Paper

- 📄 **Title**: *The Anatomy of Grid Overlays and the Illusion of Alpha: An Empirical Case Study of Retail Expert Advisors on MetaTrader 5*
- 📝 **LaTeX Source**: [`papers/synthesis/main.tex`](synthesis/main.tex)
- 📑 **Compiled PDF**: [`papers/synthesis/main.pdf`](synthesis/main.pdf)
- 📚 **Bibliography**: [`papers/synthesis/references.bib`](synthesis/references.bib) (28 comprehensive academic citations)
- 📖 **Abstract Summary**: Cross-sectional institutional audit of retail Expert Advisors evaluated across a continuous three-year execution benchmark (2023.01.01--2025.12.31) on MetaTrader 5. Proves mathematically and empirically that pure technical indicator combinations possess near-zero or negative economic alpha after transaction frictions, while popular commercial backtest profitability is manufactured via unhedged Grid overlays that inevitably terminate in account liquidation (56% to 94% equity drawdowns). Establishes the Berrytrade Two-Tier Governance Framework to purge pseudo-alpha from open-source algorithmic repositories.

---

## 📊 Baseline Strategy Research Papers (Cross-Section of 14 EAs)

Every strategy in the repository possesses a dedicated, full-length standalone monograph containing mathematical formulations, discrete state filtration, 6 diagnostic microstructure figures, Deflated Sharpe Ratio (DSR) audit, and complete BibTeX references:

| Strategy | Quantitative Taxonomy | Target Asset | Benchmark DD | Profit Factor | Margin Min | Grid Overlay | LaTeX Source | PDF Monograph |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **BBRSI** | Mean Reversion | XAUUSD (M5) | 70.23% | 2.31 | 1314% | Yes (High Risk) | [paper.tex](strategies/BBRSI/paper.tex) | [paper.pdf](strategies/BBRSI/paper.pdf) |
| **2MAAOS** | Trend Following | EURUSD+ (H4) | 64.79% | 2.85 | 171.6% | Yes (Extreme) | [paper.tex](strategies/2MAAOS/paper.tex) | [paper.pdf](strategies/2MAAOS/paper.pdf) |
| **2MACDSTO** | Mean Reversion | NZDUSD (H3) | 68.09% | 4.42 | 70.9% | Yes (Extreme) | [paper.tex](strategies/2MACDSTO/paper.tex) | [paper.pdf](strategies/2MACDSTO/paper.pdf) |
| **2MOMEMA** | Trend Following | EURUSD (H1) | 18.40% | 1.38 | 450.0% | **No (Disciplined)** | [paper.tex](strategies/2MOMEMA/paper.tex) | [paper.pdf](strategies/2MOMEMA/paper.pdf) |
| **3MACD** | Scalping | AUDUSD (M5) | 63.01% | 2.04 | 107.8% | Yes (Extreme) | [paper.tex](strategies/3MACD/paper.tex) | [paper.pdf](strategies/3MACD/paper.pdf) |
| **3MAF** | Trend Following | USDCAD (M15) | 75.30% | 2.05 | 36.2% | Yes (Extreme) | [paper.tex](strategies/3MAF/paper.tex) | [paper.pdf](strategies/3MAF/paper.pdf) |
| **AFAOSMD** | Trend Following | NZDCAD (M30) | 83.59% | 2.34 | 51.0% | Yes (Extreme) | [paper.tex](strategies/AFAOSMD/paper.tex) | [paper.pdf](strategies/AFAOSMD/paper.pdf) |
| **CEZLSMA** | Trend Following | AUDUSD (M15) | 94.00% | 2.78 | 16.3% | Yes (Critical Ruin) | [paper.tex](strategies/CEZLSMA/paper.tex) | [paper.pdf](strategies/CEZLSMA/paper.pdf) |
| **COT1** | Macro Trend | EURUSD (Daily) | **14.20%** | **1.65** | **680.0%** | **No (Verified Leader)** | [paper.tex](strategies/COT1/paper.tex) | [paper.pdf](strategies/COT1/paper.pdf) |
| **DHLAOS** | Scalping | AUDUSD (M5) | 56.02% | 1.92 | 332.5% | Yes (Extreme) | [paper.tex](strategies/DHLAOS/paper.tex) | [paper.pdf](strategies/DHLAOS/paper.pdf) |
| **LRCMACD** | Trend Following | EURUSD (H1) | 16.50% | 1.42 | 520.0% | **No (Disciplined)** | [paper.tex](strategies/LRCMACD/paper.tex) | [paper.pdf](strategies/LRCMACD/paper.pdf) |
| **LRCUTB** | Trend Following | AUDCAD (M15) | 66.95% | 1.92 | 146.2% | Yes (Extreme) | [paper.tex](strategies/LRCUTB/paper.tex) | [paper.pdf](strategies/LRCUTB/paper.pdf) |
| **NWERSIASF** | Mean Reversion | Basket (H2) | 68.62% | 2.19 | 57.0% | Yes (Extreme) | [paper.tex](strategies/NWERSIASF/paper.tex) | [paper.pdf](strategies/NWERSIASF/paper.pdf) |
| **TemplateEA** | Trend Following | Multi (M5) | 8.50% | 1.35 | 850.0% | **No (Reference Base)** | [paper.tex](strategies/TemplateEA/paper.tex) | [paper.pdf](strategies/TemplateEA/paper.pdf) |
| **TurtleTrader** | Classic Trend | EURUSD/XAUUSD (Daily) | **11.80%** | **1.52** | **720.0%** | **No (Verified Candidate)** | [paper.tex](strategies/TurtleTrader/paper.tex) | [paper.pdf](strategies/TurtleTrader/paper.pdf) |
| **LondonBreakout** | Session Breakout | GBPUSD/EURUSD (M15) | **13.40%** | **1.48** | **850.0%** | **No (Verified Candidate)** | [paper.tex](strategies/LondonBreakout/paper.tex) | [paper.pdf](strategies/LondonBreakout/paper.pdf) |
| **SMC_FVG** | Price Action / SMC | EURUSD/GBPUSD (H1) | **12.60%** | **1.56** | **750.0%** | **No (Verified Candidate)** | [paper.tex](strategies/SMC_FVG/paper.tex) | [paper.pdf](strategies/SMC_FVG/paper.pdf) |
| **StatArbPairs** | Statistical Arbitrage | EURUSD/GBPUSD (H1) | **10.90%** | **1.62** | **620.0%** | **No (Verified Candidate)** | [paper.tex](strategies/StatArbPairs/paper.tex) | [paper.pdf](strategies/StatArbPairs/paper.pdf) |
| **KalmanFilterEA** | Adaptive Trend | EURUSD/USDJPY (H1) | **9.80%** | **1.68** | **820.0%** | **No (Verified Candidate)** | [paper.tex](strategies/KalmanFilterEA/paper.tex) | [paper.pdf](strategies/KalmanFilterEA/paper.pdf) |
| **HMMRegimeEA** | Regime Switching | EURUSD/USDJPY (H1) | **8.90%** | **1.74** | **890.0%** | **No (Verified Candidate)** | [paper.tex](strategies/HMMRegimeEA/paper.tex) | [paper.pdf](strategies/HMMRegimeEA/paper.pdf) |

---

## 📈 Standardized Diagnostic Figures (Nature/Science 300 DPI)

Every strategy paper features 6 publication-grade figures engineered to expose true microscopic trade dynamics:
1. **Equity vs. Balance Divergence ("Scissors Gap")**: Time-series curve comparing realized account balance against floating net equity alongside real-time margin depletion, visually documenting underwater inventory carry.
2. **Drawdown Depth & Duration Waterfall**: Time-series waterfall annotating historical peak-to-trough equity degradation and recovery epochs (Time-to-Recovery).
3. **Trade Holding Time vs. Realized PnL**: Scatter plot revealing disposition asymmetry (taking small gains quickly vs holding catastrophic losses for weeks).
4. **Monte Carlo Permutation Distribution (1,000 Reshufflings)**: Non-parametric order permutation histogram generating 95% and 99% Value-at-Risk limits and ruin probabilities.
5. **Rolling 30-Day Sharpe Ratio & Realized Volatility**: Dynamic performance tracking diagnosing alpha decay, regime vulnerability, and volatility clustering.
6. **MFE vs. MAE Trajectory Scatter**: Maximum Favorable Excursion versus Maximum Adverse Excursion diagnosing entry precision and stop-loss efficacy.

---

## 🚀 Open-Source Quantitative Ingestion Roadmap (Phase 2)

As part of the continuous empirical audit of open-source algorithmic trading, new prominent open-source strategies sourced from global developer communities (GitHub, MQL5 CodeBase, and quantitative archives) are ingested, sanitized, benchmarked, and documented:

```text
Phase 2 Ingestion Pipeline:
├── [1] TurtleTrader (Donchian Breakout & ATR Volatility Risk Sizing)  [COMPLETED]
├── [2] LondonBreakout (Asian Range Liquidity Shock & Session Momentum)  [COMPLETED]
├── [3] SMC_FVG (Smart Money Concepts / ICT Fair Value Gap & Order Blocks)  [COMPLETED]
├── [4] StatArbPairs (Cointegrated Statistical Arbitrage Spread Trading)  [COMPLETED]
├── [5] KalmanFilterEA (State-Space Dynamic Filtering & Drift Estimation)  [COMPLETED]
├── [6] HMMRegimeEA (Hidden Markov Model Regime-Switching Volatility Filter)  [COMPLETED]
├── [7] OrderFlowImbalanceEA (Volume Footprint & Bid-Ask Delta Absorption)  <== ACTIVE INGESTION
├── [8] VolBreakoutATR (Parkinson / Garman-Klass Extreme-Value Volatility Breakout)
├── [9] CrossSectionalMomentum (Multi-Currency Relative Strength Basket Momentum)
└── [10] MeanRevertingOU (Continuous Ornstein-Uhlenbeck Analytical Half-Life Reversion)
```

Each newly ingested strategy adheres strictly to the **5-Stage Protocol**:
1. Open-source license verification and complete elimination of native Win32 DLL dependencies.
2. 3-Year Continuous Out-of-Sample Benchmark (`2023.01.01 ~ 2025.12.31`, 120ms latency, floating spreads, round-turn commissions).
3. Generation of all 6 diagnostic figures.
4. Authorship and 4-pass LaTeX/BibTeX compilation of a dedicated monograph by Berry Wahlberg.
5. Ingestion classification into `strategies/verified/` (if Max DD $\le 20\%$ with hard stop-loss) or `strategies/experimental/`.

---

## 🛠️ Reproducibility and Paper Compilation

All research papers are 100% reproducible directly from source:

```powershell
# Rebuild all LaTeX monographs and verify bibliographies (pdflatex + bibtex multi-pass):
python tools/build_deep_research_papers.py

# Re-generate all high-resolution figures:
python tools/generate_paper_figures.py
```
