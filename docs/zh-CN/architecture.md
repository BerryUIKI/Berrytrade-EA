# Berrytrade-EA 项目架构设计文档

本文档详细介绍了 **Berrytrade-EA** 开源项目的架构设计、目录层级规划以及工程化规范。

---

## 1. 核心设计理念

传统开源 MQL5 仓库往往面临三大痛点：
1. **单一目录堆砌 (Monolithic Dumping)**：所有策略 `.mq5` 散落在 `Experts/` 根目录下，缺失专属参数预设与完整回测依据。
2. **依赖分散脱节**：策略主文件在 `Experts/`，指标在 `Indicators/`，测试结果在 `Test/`，编译产物在 `Build/`。删除或升级某策略极易破坏其他策略的依赖。
3. **缺乏自动化与风控治理**：没有机器可读的元数据描述，缺乏清晰的风险分级，缺少对危险代码（如恶意 DLL 调用、无止损马丁策略）的准入审查。

**Berrytrade-EA** 采用 **模块化策略包 (Modular Strategy Package)** 架构：
- **自治与高内聚**：每个策略拥有专属独立目录，源码、参数预设 (`.set`)、回测报告 (`reports/`)、机器可读元数据 (`metadata.json`) 集中存放。
- **严格的风险分级**：对所有入库策略标注风控标签（如趋势跟踪、均值回归、网格等）。高风险策略（如马丁格尔）需强制隔离预警。
- **双层准入漏斗**：社区贡献策略初次合并进入 `strategies/experimental/`（孵化实验区）。在通过统一基准压力测试、参数鲁棒性检验和代码审计后，方可晋升至 `strategies/verified/`（验证合规区）。
- **零二进制提交**：仓库严禁提交 `.ex5` 等编译二进制文件，所有编译与回测均在本地或 CI 流水线中完成。

---

## 2. 目录结构说明

```text
Berrytrade-EA/
├── .github/                       # GitHub 工作流、Issue 与 PR 模板
│   ├── ISSUE_TEMPLATE/            # 策略提议、Bug 报告模板
│   ├── PULL_REQUEST_TEMPLATE/     # 策略入库 PR 专属审查清单
│   └── workflows/                 # CI 自动化流水线（代码检查、元数据校验）
├── docs/                          # 多语言文档体系 (支持未来 I18N 扩展)
│   ├── en/                        # 英文主文档
│   │   ├── architecture.md
│   │   ├── contribution-guidelines.md
│   │   └── ea-ingestion-specification.md
│   └── zh-CN/                     # 中文文档
│       ├── architecture.md
│       ├── contribution-guidelines.md
│       └── ea-ingestion-specification.md
├── strategies/                    # 模块化独立策略包
│   ├── verified/                  # 官方验证/高信度策略区
│   └── experimental/              # 社区贡献/前沿实验孵化区
│       └── <策略名称>/
│           ├── src/               # EA 源码 (.mq5)
│           ├── presets/           # MT5 参数预设文件 (.set)
│           ├── reports/           # 回测报告 (HTML/JSON/资金曲线)
│           ├── metadata.json      # 策略元数据 (作者、版本、标的、周期、风控属性)
│           └── README.md          # 策略说明文档 (原理、核心逻辑、参数说明、风险提示)
├── shared/                        # 跨策略复用的通用库
│   ├── Include/                   # 通用头文件 (.mqh)
│   │   └── Berrytrade/            # 核心风控、订单抽象封装
│   ├── Indicators/                # 共享公共指标
│   └── Scripts/                   # 辅助脚本
├── benchmarks/                    # 统一回测基准环境与数据集
│   ├── standards.json             # 基础滑点、点差、佣金、本金与回测规范
│   └── README.md                  # 基准测试方法学与说明
├── tools/                         # 开发运维与自动化工具链
│   ├── validate_ea.py             # 策略元数据与安全合规校验工具
│   ├── generate_catalog.py        # 自动抓取元数据生成 README 策略矩阵表
│   └── sync_to_mt5.ps1            # 同步/软链接至本地 MT5 终端的自动化脚本
├── .gitignore                     # 忽略二进制、日志及敏感环境数据
├── CONTRIBUTING.md                # 贡献者指南入口
├── LICENSE                        # MIT 开源许可证
├── README.md                      # 英文主页
└── README.zh-CN.md                # 中文主页
```

---

## 3. 策略包标准结构 (Strategy Package Layout)

任何置于 `strategies/{verified|experimental}/<策略名称>` 目录下的策略必须满足下列规范：

| 组成部分 | 路径 | 是否必填 | 功能与说明 |
| :--- | :--- | :---: | :--- |
| **源码** | `src/<策略名称>.mq5` | **是** | 规范命名、带英文/中文注释的 MQL5 源码。 |
| **元数据** | `metadata.json` | **Yes** | 包含策略名称、作者、建议品种、周期、风险类型等。 |
| **文档** | `README.md` | **是** | 说明策略底层逻辑、指标使用、入场出场规则与风控约束。 |
| **参数预设** | `presets/*.set` | **是** | 至少提供一份可在真实或模拟盘测试的 `.set` 预设。 |
| **回测报告** | `reports/` | **是** | 包含 MT5 策略测试报告或 `summary.json` 关键指标汇总。 |

---

## 4. 与 MetaTrader 5 终端的协同

由于 MetaTrader 5 强制要求代码存放在 `MQL5/Experts`、`MQL5/Include` 等固定目录下，本项目提供了同步工具：
- 运行 `powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<MT5数据目录>"`，脚本将自动建立软链接（Symbolic Links）或分发同步，既保持 Git 仓库的高内聚模块化，又满足 MT5 编译运行需求。
