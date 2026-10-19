# 🤖 Berrytrade-EA

<p align="center">
  <strong>面向 MetaTrader 5 (MQL5) 的工程级开源量化交易 EA 与基准回测体系</strong>
</p>

<p align="center">
  <a href="README.md"><strong>English</strong></a> | 
  <a href="README.zh-CN.md"><strong>简体中文</strong></a> | 
  <a href="wiki/Home-zh.md"><strong>用户知识库 (Wiki)</strong></a> |
  <a href="AGENTS.md"><strong>AI Agent 治理守则</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/语言-MQL5-blue.svg" alt="MQL5">
  <img src="https://img.shields.io/badge/平台-MetaTrader%205-orange.svg" alt="MetaTrader 5">
  <img src="https://img.shields.io/badge/开源协议-MIT-green.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/分支模型-GitFlow-blueviolet.svg" alt="GitFlow">
  <img src="https://img.shields.io/badge/CI-自动化质检-success.svg" alt="CI Audit">
</p>

---

## 📖 项目简介

**Berrytrade-EA** 是一个致力于推动 MetaTrader 5 (MT5) 算法交易标准化、透明化与可复现性的开源社区项目。

与常见的无序堆砌 `.mq5` 文件、缺乏参数预设与风控审计的传统代码库不同，**Berrytrade-EA** 秉承以下工程准则：
- **模块化策略包 (Modular Strategy Packages)**：每个 EA 拥有独立自治目录，统一包含源码、`.set` 参数预设、回测报告与机器可读元数据。
- **严格的风控治理**：强制要求硬止损（Hard Stop-Loss）；对逆势加倍马丁格尔（Martingale）或无保护网格实行高风险警示与隔离。
- **双层准入漏斗**：社区贡献策略初次提交进入 `experimental/`（孵化实验区），经过多年度统一基准回测与代码审计后晋升至 `verified/`（官方验证区）。
- **自动化安全 CI**：内置安全扫描器，阻断恶意 Win32 DLL 导入、外泄后门与破损格式。
- **学术级实证研究**：每个策略均配备由 **Berry Wahlberg** (`Berrytrade Quantitative Research`) 撰写的独立 arXiv 格式论文与 Nature 级高分辨率诊断图表。

---

## 📚 文档分层体系 (Documentation Policy)

本项目严格区分**智能体治理规范**、**开发者技术文档**与**用户知识库**：

| 文档类型 | 目标受众 | 语言策略 | 存放位置 |
| :--- | :--- | :---: | :--- |
| **AI Agent 治理与协同守则** | 自主代码智能体、AI 结对编程助手 | **仅限英文 (English Only)** | [**`AGENTS.md`**](AGENTS.md) |
| **开发者技术文档** | 量化研究员、MQL5 开发者、代码贡献者 | **仅限英文 (English Only)** | [`docs/developer/`](docs/developer/) |
| **量化学术论文与预印本** | 学术界同行、机构投资者、量化配置人 | **LaTeX / 英文 arXiv** | [`papers/`](papers/) |
| **用户知识库与使用指南** | 实盘/模拟盘交易者、普通终端用户 | **多语言支持 (中 / 英)** | [`wiki/`](wiki/) 与 GitHub Wiki |

- 🤖 **Agent 智能体守则**：[AI Agent 规范 (AGENTS.md)](AGENTS.md) &bull; [Agent 规范细节](docs/developer/agents.md)
- 🛠️ **开发者技术文档 (英文)**：[项目架构](docs/developer/architecture.md) &bull; [EA 入库与审核规范](docs/developer/ea-ingestion-specification.md) &bull; [贡献者指南](docs/developer/contribution-guidelines.md) &bull; [基准回测标准](docs/developer/benchmarking-standards.md)
- 📑 **学术研究论文**：[横向汇总论文主干](papers/synthesis/main.pdf) &bull; [14 篇策略单行本论文索引](papers/README.md)
- 📖 **用户知识库 (支持中文)**：[新手上手指南](wiki/Getting-Started-zh.md) &bull; [资金风控守则](wiki/Risk-Management-zh.md) &bull; [策略选型手册](wiki/Strategy-Catalog-zh.md) &bull; [常见问题排错](wiki/Troubleshooting-and-FAQ-zh.md)

---

## 📑 量化学术研究论文（arXiv 格式）

本项目所有策略均经过由 **Berry Wahlberg** (`Berrytrade Quantitative Research`) 主持的 3 年期真实微观执行回测（2023--2025，120ms 网络延迟，实盘浮动点差与 $7/手佣金）及学术级评测：

- 🏛️ **横向全景汇总论文**：[*The Illusion of Alpha in Retail Algorithmic Trading: An Empirical Dissection of Indicator-Driven Expert Advisors and the Hidden Tail-Risk of Grid Overlays on MetaTrader 5*](papers/synthesis/main.pdf)（[LaTeX 源码](papers/synthesis/main.tex)）
- 📊 **策略独立测试报告论文**：全套 14 篇针对单个策略数学模型、微观结构诊断与尾部风险解构的独立论文汇总于 [**`papers/README.md`**](papers/README.md)。

---

## 📊 策略索引总表

以下索引表由策略目录下的 `metadata.json` 自动解析渲染：

### 已验证策略（生产基准层）

*严格准入要求：最大净值回撤 $\le 20\%$、强制硬止损、严禁无对冲网格/马丁、卡玛比率 $\ge 1.5$。*

> **实盘基准冠军（审核晋升候选）**：
> - **[`COT1`](strategies/experimental/COT1)**：**最大净值回撤仅 14.20%**，**盈亏比 1.65**，**净利润 +$28,450**，**最低预付款比例 680.0%**，单笔严谨执行，融合美国 CFTC 商业机构持仓情绪与 SuperTrend 动态波动率追踪。

### 实验孵化策略（社区前沿层）

| 策略名称 | 分类 | 风险等级 | 支持品种 | 周期 | 初始资金 | 策略简述 |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| [COT1](strategies/experimental/COT1) | `trend_following` | **Medium** | EURUSD | Daily | $1,000 | Commitments of Traders (COT) report sentiment with SuperTrend (实测基准冠军). |
| [LRCMACD](strategies/experimental/LRCMACD) | `trend_following` | **High** | EURUSD | H1 | $1,000 | Linear Regression Channel and MACD trend strategy (严格单笔止损，无网格). |
| [2MOMEMA](strategies/experimental/2MOMEMA) | `trend_following` | **High** | EURUSD | H1 | $1,000 | Dual Momentum and EMA trend filter strategy (严格单笔止损，无网格). |
| [TemplateEA](strategies/experimental/TemplateEA) | `trend_following` | **Low** | XAUUSD, EURUSD | M5 | $1,000 | 官方标准化模板（单笔止损、模块化、标准资金管理）. |
| [BBRSI](strategies/experimental/BBRSI) | `mean_reversion` | **High** | XAUUSD | M5 | $1,000 | Bollinger Bands and RSI mean reversion strategy (支持无网格硬止损模式). |
| [2MAAOS](strategies/experimental/2MAAOS) | `trend_following` | **Extreme** | EURUSD, EURCAD, USDCAD | H4 | $10,000 | Dual Moving Averages and Andean Oscillator with Grid overlay. |
| [2MACDSTO](strategies/experimental/2MACDSTO) | `mean_reversion` | **Extreme** | NZDUSD | H3 | $10,000 | Dual MACDs and Stochastic Oscillator with Grid overlay. |
| [3MACD](strategies/experimental/3MACD) | `scalping` | **Extreme** | AUDUSD | M5 | $10,000 | Triple MACD scalping strategy with Grid overlay. |
| [3MAF](strategies/experimental/3MAF) | `trend_following` | **Extreme** | USDCAD | M15 | $10,000 | Three Moving Averages and Williams Fractals with Grid overlay. |
| [AFAOSMD](strategies/experimental/AFAOSMD) | `trend_following` | **Extreme** | NZDCAD | M30 | $10,000 | Average Force, Andean Oscillator, and MACD with Grid overlay. |
| [CEZLSMA](strategies/experimental/CEZLSMA) | `trend_following` | **Extreme** | AUDUSD | M15 | $10,000 | Chandelier Exit and Zero Lag SMA (ZLSMA) with Grid overlay (94% 回撤，濒临爆仓). |
| [DHLAOS](strategies/experimental/DHLAOS) | `scalping` | **Extreme** | AUDUSD | M5 | $10,000 | Daily High/Low and Andean Oscillator scalping with Grid overlay. |
| [LRCUTB](strategies/experimental/LRCUTB) | `trend_following` | **Extreme** | AUDCAD | M15 | $10,000 | Linear Regression Candles and UT Bot alerts with Grid overlay. |
| [NWERSIASF](strategies/experimental/NWERSIASF) | `mean_reversion` | **Extreme** | USDCAD, AUDUSD, EURCHF | H2 | $10,000 | Nadaraya-Watson Envelope, RSI, and ATR Stop Loss Finder with Grid overlay. |

---

## 🚀 开源策略持续引入路线图（Phase 2）

我们正在全面检索互联网（GitHub、MQL5 CodeBase 及经典量化开源库）中的知名开源策略，并按以下顺序逐一完成代码审计、3 年基准测试与学术论文发表：

1. **`TurtleTrader`**（经典海龟交易法则：唐奇安通道 20/10 突破 + N-波动率头寸分配 + 2N 移动止损）&mdash; **[当前推进中]**
2. **`LondonBreakout`**（伦敦开盘区间突破：亚洲盘震荡区间流动性爆发，日内单笔清仓）
3. **`SMC_FVG`**（Smart Money Concepts / ICT 机构订单流：合理价值缺口与流动性掠夺）
4. **`StatArbPairs`**（多品种统计套利：基于协整残差 Z-Score 偏离的均值回归配对对冲）
5. **`KalmanFilterEA`**（卡尔曼滤波自适应状态估计：消除均线滞后的动态漂移估计系统）

---

## 🔀 GitFlow 分支规范与开发守则

本项目所有开发与 AI Agent 自动化推进必须严格遵守 GitFlow 规范：

- **`main`**：生产就绪与官方发布分支，严禁直接推送提交。
- **`develop`**：核心集成与集成分支，所有功能分支均由此分出并汇入。
- **`feature/<name>`**：独立功能/策略开发分支（如 `feature/ea-turtle-trader`、`feature/docs-update`）。
- **提交准则**：“小步PR，频繁commit”，采用 [Conventional Commits](https://www.conventionalcommits.org/) 格式（`feat`, `test`, `docs`, `fix`, `ci`）。

---

## 🏗️ 仓库目录结构

```text
Berrytrade-EA/
├── .github/                       # GitHub 工作流、Issue 与 PR 模板
├── AGENTS.md                      # AI Agent 治理与结对编程技术规范
├── docs/developer/                # 开发者技术文档 (纯英文)
│   ├── architecture.md
│   ├── agents.md
│   ├── benchmarking-standards.md
│   ├── contribution-guidelines.md
│   └── ea-ingestion-specification.md
├── wiki/                          # 用户多语言文档与知识库 (同步发布至 GitHub Wiki)
├── papers/                        # arXiv 学术研究论文 (Berry Wahlberg 署名)
│   ├── synthesis/                 # 横向全景论文源码与 10 幅全景图表
│   └── strategies/<Strategy>/     # 独立策略学术单行本论文与参考文献 (.bbl)
├── strategies/                    # 模块化独立策略包
│   ├── verified/                  # 官方验证/高信度策略区 (回撤 <= 20%)
│   └── experimental/              # 社区贡献/前沿实验孵化区
│       └── <策略名称>/
│           ├── src/               # EA 源码 (.mq5)
│           ├── presets/           # MT5 参数预设文件 (.set)
│           ├── reports/           # 回测报告摘要与测试详情
│           ├── metadata.json      # 机器可读元数据规范
│           └── README.md          # 策略独立使用与数学说明
├── shared/                        # 跨策略公共库与复用头文件
│   ├── Include/                   # 通用工具类、指标封装与数学库
│   └── Indicators/                # 共享自定义指标源码
├── benchmarks/                    # 标准化测试环境定义与基准数据集
│   └── standards.json             # 基准经纪商成本与执行约束
├── tools/                         # 开发辅助工具、CI 质检器、论文构建器
│   ├── validate_ea.py             # 语法与规范格式自动化校验器
│   ├── generate_catalog.py        # 策略目录自动生成器
│   ├── generate_paper_figures.py  # 300 DPI 期刊级诊断图表生成器
│   ├── build_deep_research_papers.py # LaTeX + BibTeX 自动化多轮编译器
│   ├── sync_to_mt5.ps1            # 同步部署至本地 MT5 终端脚本
│   └── publish_wiki.ps1           # 本地 wiki 自动化发布至 GitHub Wiki 脚本
├── CONTRIBUTING.md                # 贡献者指南入口
├── LICENSE                        # MIT 开源许可证
└── README.md                      # 项目英文首页
```

---

## 🚀 快速上手：部署至本地 MetaTrader 5

一键将 Berrytrade 全套策略与指标部署至您的本地 MT5 终端：

```powershell
# 运行自动化同步与符号链接脚本
powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<您的_MT5_数据目录路径>"
```

*提示：在 MetaTrader 5 终端中点击 **文件 (File) -> 打开数据文件夹 (Open Data Folder)** 即可查阅您的 MT5 实际数据路径。*

---

## 🚨 风险免责声明

**自主承担风险 (USE AT YOUR OWN RISK)：** 外汇、贵金属、CFD 及其他金融衍生品交易具备极高资金风险，可能并不适合所有投资者。高财务杠杆既能扩大收益，也能瞬间加速损失。

- **非投资建议**：本仓库包含的全部策略、指标、算法模型与测试报告仅供学术研究、教学模拟与开源代码交流之用，绝不构成任何直接投资建议。
- **历史表现不代表未来**：回测表现、历史模拟及样本内优化数据均无法保证未来的实际实盘收益。
- **免责声明**：本项目维护者、研究员与所有代码贡献者概不承担任何个人因直接或间接参考、部署本仓库软件所导致的任何财务损失或法律责任。
