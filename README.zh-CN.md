# 🤖 Berrytrade-EA

<p align="center">
  <strong>面向 MetaTrader 5 (MQL5) 的工程级开源量化交易 EA 与基准回测体系</strong>
</p>

<p align="center">
  <a href="README.md"><strong>English</strong></a> | 
  <a href="README.zh-CN.md"><strong>简体中文</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/语言-MQL5-blue.svg" alt="MQL5">
  <img src="https://img.shields.io/badge/平台-MetaTrader%205-orange.svg" alt="MetaTrader 5">
  <img src="https://img.shields.io/badge/开源协议-MIT-green.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/PRs-欢迎提交-brightgreen.svg" alt="PRs Welcome">
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

---

## 📊 策略索引总表

以下索引表由策略目录下的 `metadata.json` 自动解析渲染：

### 已验证策略（生产基准层）

*当前该层级暂无入库策略。*

### 实验孵化策略（社区前沿层）

| 策略名称 | 分类 | 风险等级 | 支持品种 | 周期 | 初始资金 | 策略简述 |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| [TemplateEA](strategies/experimental/TemplateEA) | `trend_following` | **Low** | XAUUSD, EURUSD | M5 | $1,000 | Standardized MQL5 EA template showcasing risk management, hard stop-loss, and modular structure. |

---

## 🏗️ 仓库目录结构

```text
Berrytrade-EA/
├── .github/                       # GitHub 工作流、Issue 与 PR 模板
├── docs/                          # 多语言文档体系 (支持未来 I18N 扩展)
│   ├── en/                        # 英文主文档
│   └── zh-CN/                     # 中文参考文档
├── strategies/                    # 模块化独立策略包
│   ├── verified/                  # 官方验证/高信度策略区
│   └── experimental/              # 社区贡献/前沿实验孵化区
│       └── <策略名称>/
│           ├── src/               # EA 源码 (.mq5)
│           ├── presets/           # MT5 参数预设文件 (.set)
│           ├── reports/           # 回测报告摘要与测试详情
│           ├── metadata.json      # 策略元数据 (作者、版本、周期、风控)
│           └── README.md          # 策略说明文档
├── shared/                        # 跨策略复用的通用库
│   ├── Include/Berrytrade/        # 核心风控、订单封装
│   ├── Indicators/                # 共享公共指标
│   └── Scripts/                   # 辅助脚本
├── benchmarks/                    # 统一回测基准环境与数据集规范
│   └── standards.json             # 基础滑点、点差、佣金基准
├── tools/                         # 开发运维与自动化工具链
│   ├── validate_ea.py             # 策略元数据与安全合规校验工具
│   ├── generate_catalog.py        # 自动抓取元数据生成 README 策略矩阵表
│   └── sync_to_mt5.ps1            # 同步/软链接至本地 MT5 终端的自动化脚本
├── CONTRIBUTING.md                # 贡献者指南入口
├── LICENSE                        # MIT 开源许可证
└── README.zh-CN.md                # 中文主页
```

详细架构设计请参阅 [项目架构设计文档 (中文)](docs/zh-CN/architecture.md)。

---

## 🚀 快速开始：部署至 MetaTrader 5

运行以下命令，即可一键将仓库中的策略及共享依赖安装至本地 MT5 终端：

```powershell
# 运行同步部署脚本
powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<您的_MT5_数据目录路径>"
```

*提示：在 MetaTrader 5 顶部菜单点击 **文件 (File) -> 打开数据文件夹 (Open Data Folder)** 即可获取您的数据目录绝对路径。*

---

## 📥 EA 入库与贡献流程 (PR 规范)

我们热忱欢迎交易开发者向本仓库提交 EA。所有提交均需遵循以下入库流程：

```mermaid
flowchart LR
    A["1. 打包策略"] --> B["2. 本地合规校验"]
    B --> C["3. 提交 PR"]
    C --> D["4. 自动 CI 与代码审查"]
    D --> E["5. 合并入库"]
```

1. **打包策略**：在 `strategies/experimental/<策略英文名>/` 下准备完整策略文件包：
   - `src/<策略英文名>.mq5`
   - `presets/<预设名称>.set`
   - `reports/summary.json`
   - `metadata.json`
   - `README.md`
2. **本地运行校验**：
   ```powershell
   python tools/validate_ea.py --path strategies/experimental/<策略英文名>
   ```
3. **发起 Pull Request**：使用仓库预置的 [PR 模板](.github/PULL_REQUEST_TEMPLATE/pull_request_template.md) 提交合并请求，并完成自检勾选。
4. **深入阅读入库标准**：
   - [EA 入库与贡献规范标准 (中文)](docs/zh-CN/ea-ingestion-specification.md)
   - [贡献者指南 (中文)](docs/zh-CN/contribution-guidelines.md)

---

## 🚨 风险提示与免责声明

**交易有风险，入市需谨慎：** 金融衍生品、外汇、贵金属及差价合约（CFD）交易具备极高杠杆风险，并非适合所有投资者。杠杆既可能放大收益，也可能成倍放大损失。

- **非投资建议**：本仓库包含的策略、指标、脚本及分析工具仅供学术研究、教学与量化回测参考，绝不构成任何实质性投资或交易建议。
- **无盈利保证**：历史回测收益、模拟盘表现及历史统计数据不能作为未来真实盈利的保证。
- **免责声明**：本项目的维护者、作者及贡献者对于使用者因运行本项目代码所导致的任何直接或间接资金损失不承担任何法律或经济责任。
