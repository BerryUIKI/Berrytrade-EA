# 📑 Berrytrade Quantitative Research Papers

> **Author**: Berry Wahlberg (`Berrytrade Quantitative Research`)  
> **Format**: arXiv Quantitative Finance Preprint (`q-fin.TR`, `q-fin.PM`)

---

## 🏛️ Master Synthesis Paper

- 📄 **Title**: *The Illusion of Alpha in Retail Algorithmic Trading: An Empirical Dissection of Indicator-Driven Expert Advisors and the Hidden Tail-Risk of Grid Overlays on MetaTrader 5*
- 📝 **Source**: [`papers/synthesis/main.tex`](synthesis/main.tex)
- 📑 **Compiled PDF**: [`papers/synthesis/main.pdf`](synthesis/main.pdf)
- 📖 **Summary**: Cross-sectional analysis of 14 Expert Advisors evaluated under the 3-year Berrytrade Benchmark (2023--2025). Documents that pure indicators have near-zero alpha, while unhedged grids induce 56%--94% relative drawdowns and inevitable 2024 account blowouts.

---

## 📊 Individual Strategy Research Papers

Each strategy in the repository has a dedicated, full-length LaTeX research paper dissecting its mathematical formulation, backtest metrics, and tail-risk exposure:

| Strategy | Taxonomy | Primary Asset | Drawdown | Profit Factor | LaTeX Source | PDF Report |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **2MAAOS** | Trend Following | EURUSD, EURCAD, | 64.79\% | 2.85 | [paper.tex](strategies/2MAAOS/paper.tex) | [paper.pdf](strategies/2MAAOS/paper.pdf) |
| **2MACDSTO** | Mean Reversion | NZDUSD | 68.09\% | 4.42 | [paper.tex](strategies/2MACDSTO/paper.tex) | [paper.pdf](strategies/2MACDSTO/paper.pdf) |
| **2MOMEMA** | Trend Following | EURUSD | 18.40\% | 1.38 | [paper.tex](strategies/2MOMEMA/paper.tex) | [paper.pdf](strategies/2MOMEMA/paper.pdf) |
| **3MACD** | Scalping | AUDUSD | 63.01\% | 2.04 | [paper.tex](strategies/3MACD/paper.tex) | [paper.pdf](strategies/3MACD/paper.pdf) |
| **3MAF** | Trend Following | USDCAD | 75.30\% | 2.05 | [paper.tex](strategies/3MAF/paper.tex) | [paper.pdf](strategies/3MAF/paper.pdf) |
| **AFAOSMD** | Trend Following | NZDCAD | 83.59\% | 2.34 | [paper.tex](strategies/AFAOSMD/paper.tex) | [paper.pdf](strategies/AFAOSMD/paper.pdf) |
| **BBRSI** | Mean Reversion | XAUUSD | 70.23\% | 2.31 | [paper.tex](strategies/BBRSI/paper.tex) | [paper.pdf](strategies/BBRSI/paper.pdf) |
| **CEZLSMA** | Trend Following | AUDUSD | 94.00\% | 2.78 | [paper.tex](strategies/CEZLSMA/paper.tex) | [paper.pdf](strategies/CEZLSMA/paper.pdf) |
| **COT1** | Macro Trend | EURUSD | 14.20\% | 1.65 | [paper.tex](strategies/COT1/paper.tex) | [paper.pdf](strategies/COT1/paper.pdf) |
| **DHLAOS** | Scalping | AUDUSD | 56.02\% | 1.92 | [paper.tex](strategies/DHLAOS/paper.tex) | [paper.pdf](strategies/DHLAOS/paper.pdf) |
| **LRCMACD** | Trend Following | EURUSD | 16.50\% | 1.42 | [paper.tex](strategies/LRCMACD/paper.tex) | [paper.pdf](strategies/LRCMACD/paper.pdf) |
| **LRCUTB** | Trend Following | AUDCAD | 66.95\% | 1.92 | [paper.tex](strategies/LRCUTB/paper.tex) | [paper.pdf](strategies/LRCUTB/paper.pdf) |
| **NWERSIASF** | Mean Reversion | USDCAD, AUDUSD, | 68.62\% | 2.19 | [paper.tex](strategies/NWERSIASF/paper.tex) | [paper.pdf](strategies/NWERSIASF/paper.pdf) |
| **TemplateEA** | Trend Following | XAUUSD, EURUSD | 8.50\% | 1.35 | [paper.tex](strategies/TemplateEA/paper.tex) | [paper.pdf](strategies/TemplateEA/paper.pdf) |

---

## 🛠️ How to Compile Papers

To recompile all papers from LaTeX sources:
```powershell
python tools/generate_and_build_papers.py
```
