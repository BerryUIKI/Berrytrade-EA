# 贡献者指南 (Contribution Guidelines)

感谢关注并参与 **Berrytrade-EA** 开源社区！我们热忱欢迎全球量化交易者、MQL5 开发者及研究人员贡献策略、通用工具与优化方案。

---

## 1. 语言规范与 I18N 国际化支持

- **主要语言 (English 英文)**：
  - 所有 GitHub PR 标题、描述正文与评审讨论统一使用英文。
  - 所有 GitHub Issue 及 Bug 报告使用英文撰写。
  - MQL5 核心源码注释、函数说明、Input 参数说明和运行日志输出必须包含英文。
  - 项目根目录 `README.md` 与 `docs/en/` 为全局权威文档。
- **第二语言 (中文 / zh-CN)**：
  - 中文文档存放于 `docs/zh-CN/` 及根目录 `README.zh-CN.md`。
  - 策略包内的 `README.md` 鼓励提供中英文双语版本。
- **未来 I18N 架构扩展**：
  - 文档体系遵循镜像文件路径：`docs/<语言代码>/<模块名称>.md`。
  - 新增核心文档时，英文为必填；中文及其他语言翻译可通过社区协作持续补全。

---

## 2. Git 分支管理与提交规范

### 2.1 分支命名规范
- 新增 EA 提交：`feat/ea-<策略英文名>` (例如 `feat/ea-bollinger-rsi`)
- 公共模块/头文件更新：`feat/shared-<功能名>`
- Bug 修复：`fix/<问题描述>`
- 文档与翻译更新：`docs/<主题名>`
- 基准评测数据更新：`benchmark/<策略名>`

### 2.2 Commit 提交信息格式
遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/) 语义化提交标准：
```text
<type>(<scope>): <简要概述>

[详细变更内容]

[关联 Issue 编号]
```

常用类型：
- `feat`: 新增策略包或共享工具库。
- `fix`: 修复逻辑漏洞或参数错误。
- `docs`: 文档撰写、更新或多语言翻译。
- `test`: 补充回测报告、`.set` 预设或校验脚本。
- `refactor`: 重构代码，不改变原有交易逻辑。
- `ci`: CI 流水线与工具链优化。

---

## 3. MQL5 代码工程规范

为保障策略长效运行与跨经纪商稳健性，需遵循以下编码规范：

1. **输入参数规范 (Inputs)**：
   - 所有用户可调参数统一以 `Inp` 为前缀（例如 `input double InpRiskPercent = 0.5;`）。
   - 参数必须在行末添加英文注释，以在 MT5 参数设置窗口展示友好提示：
     ```mql5
     input double InpTakeProfitPoints = 200.0; // 止盈点数 (Points)
     input double InpStopLossPoints   = 100.0; // 硬止损点数 (Points)
     ```
2. **命名约定**：
   - 类名：`PascalCase`（例如 `CTradeRiskManager`）。
   - 函数与方法：`PascalCase`（例如 `CheckEntrySignal()`）。
   - 成员变量：`m_camelCase`（例如 `m_magicNumber`）。
   - 常量与宏：`UPPER_SNAKE_CASE` 或 `ENUM_...`。
3. **风控合规校验**：
   - 必须在下单前动态校验经纪商的最小止损距离（`SYMBOL_TRADE_STOPS_LEVEL`）、最小手数（`SYMBOL_VOLUME_MIN`）及步长（`SYMBOL_VOLUME_STEP`）。
   - 严禁出现无止损（Hard Stop-Loss）裸奔开仓代码。
4. **杜绝绝对本地路径**：
   - 严禁硬编码 Windows 本地绝对路径（如 `C:\Users\...`），必须通过 MQL5 原生 API 获取终端数据目录。

---

## 4. 提交策略 PR 详细操作步骤

1. Fork 官方仓库至个人 GitHub，并 Clone 到本地。
2. 创建特性分支：`git checkout -b feat/ea-my-strategy`。
3. 在 `strategies/experimental/<策略英文名>/` 下构建符合 [EA 入库规范标准](file:///f:/dev/Berrytrade-EA/docs/zh-CN/ea-ingestion-specification.md) 的完整策略包：
   - `src/<策略名>.mq5`
   - `presets/Default_<品种>_<周期>.set`
   - `reports/summary.json`
   - `metadata.json`
   - `README.md`
4. 运行本地合规校验脚本：
   ```powershell
   python tools/validate_ea.py --path strategies/experimental/<策略英文名>
   ```
5. 提交变更并推送至个人远程分支。
6. 前往 GitHub 发起 Pull Request，目标分支为 `main`，并选择 **EA Submission Template** 模板。
7. 根据维护者审查意见（Code Review）调整并更新代码，通过后合并入库。
