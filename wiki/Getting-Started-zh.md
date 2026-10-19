# 新手上路指南 (Getting Started)

<p align="center">
  <a href="Getting-Started"><strong>English</strong></a> | 
  <a href="Getting-Started-zh"><strong>简体中文</strong></a>
</p>

本指南将引导您完成 MetaTrader 5 的基础环境准备、Berrytrade-EA 策略安装、加载 `.set` 参数预设，并在图表上正式运行 EA。

---

## 第一步：准备 MetaTrader 5 终端
1. 从合规经纪商或 MetaQuotes 官网下载并安装 MetaTrader 5 客户端。
2. 强烈建议先在**模拟账户（Demo Account）**中运行验证，严禁直接在未经验证的真实账户上实盘挂机。

---

## 第二步：安装 Berrytrade-EA 策略

### 方式一：自动化一键部署（推荐）
本项目提供了 PowerShell 自动部署脚本，可一键完成策略、公共依赖库与参数的映射：

1. 在 MT5 顶部菜单栏点击 **文件 (File) -> 打开数据文件夹 (Open Data Folder)**。
2. 在弹出的 Windows 文件资源管理器地址栏中，复制完整路径（例如 `C:\Users\<用户名>\AppData\Roaming\MetaQuotes\Terminal\<32位字符ID>`）。
3. 在 `Berrytrade-EA` 项目根目录下打开 PowerShell 终端，执行：
   ```powershell
   powershell ./tools/sync_to_mt5.ps1 -MT5DataPath "<您的MT5数据目录路径>"
   ```
4. 重启 MT5，或者在左侧导航器（Navigator）的“智能交易系统 (Expert Advisors)”上右键点击 **刷新 (Refresh)**。

### 方式二：手动复制安装
1. 将 `strategies/{tier}/<EA>/src/*.mq5` 复制到 `<MT5数据目录>/MQL5/Experts/Berrytrade/<EA>/`。
2. 将 `shared/Include/Berrytrade/` 复制到 `<MT5数据目录>/MQL5/Include/Berrytrade/`。
3. 将 `strategies/{tier}/<EA>/presets/*.set` 复制到 `<MT5数据目录>/MQL5/Profiles/Tester/`。
4. 按键盘快捷键 `F4` 打开 MetaEditor，双击目标 `.mq5`，按 `F7` 完成编译。

---

## 第三步：在 MT5 中开启自动交易权限
EA 需要获得授权才能进行开平仓操作：

1. 打开菜单 **工具 (Tools) -> 选项 (Options) -> 智能交易系统 (Expert Advisors)**（快捷键 `Ctrl+O`）。
2. 勾选 **“允许算法交易 (Allow Algo Trading)”**。
3. 在 MT5 顶部工具栏中，确认 **“算法交易 (Algo Trading)”** 按钮已点击，处于**绿色播放标志**的激活状态。

---

## 第四步：挂载 EA 并加载预设文件

1. 在 MT5 交易品种列表（Market Watch）中，右键点击目标品种（如 `XAUUSD` 黄金），选择 **图表窗口 (Chart Window)**。
2. 按照策略文档切换至推荐的图表周期（如 `M5` 5分钟图）。
3. 在左侧“导航”面板中展开 **智能交易系统 -> Berrytrade**，将对应 EA 拖拽到图表中央。
4. 在弹出的 EA 属性设置窗口中：
   - 切换到 **输入参数 (Inputs)** 选项卡。
   - 点击右下角的 **加载 (Load...)** 按钮，选择策略自带的预设文件（如 `Default_XAUUSD_M5.set`）。
   - 根据个人风控承受力微调参数（例如单笔风险百分比 `InpRiskPercent`）。
5. 点击 **确定 (OK)**。
6. 检查图表右上角是否出现蓝色帽子或绿色小图标，出现即代表 EA 正在实时监听行情并运行。
