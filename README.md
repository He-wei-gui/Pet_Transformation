# 蜕变记 · Pet Transform 🦎

> 一款基于 HarmonyOS（ArkTS / ArkUI）的**宠物成长记录系统**，专为爬宠（守宫、蜥蜴、蛇等）养护打造。
> 复刻并增强自 [pet-reptile-tracker](https://github.com/lysyminger/pet-reptile-tracker)，新增蜕皮 / 环境 / 成长相册 / 日历提醒 / 数据统计，并提供登录注册、中英双语与浅深主题。

应用名「蜕变记」取自爬宠**蜕皮（蜕）成长（变）记录（记）** —— 用心记录每一次蜕变。

---

## ✨ 功能特性

| 模块 | 说明 |
|------|------|
| 🔐 登录注册 | 账号密码注册/登录，密码加盐 SHA256 哈希，会话本地持久化 |
| 🏠 今日待办 | 聚合所有宠物的喂食/换料任务，按 **逾期 → 今日 → 未来** 排序，三色紧急度标签 |
| 🦎 宠物管理 | 宠物列表 / 详情 / 新增 / 编辑 / 删除（级联删除其全部记录），emoji 头像选择 |
| ⚖️ 体重记录 | 录入称重，**Canvas 手绘体重趋势曲线** |
| 🍽️ 喂食 / 🪵 换料 | 记录即按"实际打卡日 + 间隔"**动态重算下次日期**（核心业务逻辑） |
| 🐍 蜕皮记录 | 开始 / 完成状态时间线 |
| 🌡️ 环境记录 | 温度 / 湿度 / UVB 录入 + 温度趋势曲线 |
| 📷 成长相册 | 系统图库选图 → 复制进应用沙箱 → 记录体长 / 说明，网格展示 |
| 📅 日历视图 | 自绘月历网格、事件圆点标注、选中日待办、**本地通知提醒** |
| 📊 数据统计 | 概览卡片（宠物 / 喂食 / 称重 / 逾期）+ 近 7 天喂食柱状图 |
| 🌐 国际化 | 应用内一键切换 **中文 / English**，跟随或覆盖系统语言 |
| 🌙 主题 | **浅色 / 深色** 双主题，可手动切换并持久化 |

---

## 🧱 技术栈

- **语言 / 框架**：ArkTS、ArkUI（声明式 UI，`@Component` V1 + `@State/@Prop/@Watch` + `AppStorage`）
- **目标平台**：HarmonyOS，API 22（6.0.2），phone
- **本地存储**：`@kit.ArkData`
  - `relationalStore`（关系型数据库，8 张表）—— 业务数据
  - `preferences`（轻量键值）—— 会话 / 设置
- **图表**：原生 `Canvas` 手绘（无第三方图表库）
- **加密**：`@kit.CryptoArchitectureKit`（SHA256 + 盐）
- **媒体**：`@kit.MediaLibraryKit`（`PhotoViewPicker` 选图）+ `@kit.CoreFileKit`（沙箱文件复制）
- **通知**：`@kit.NotificationKit`（本地提醒）
- **国际化**：`@kit.LocalizationKit`（`i18n.System.setAppPreferredLanguage`）
- **测试**：`@ohos/hypium`（单元测试）

---

## 🗂️ 项目结构

```
entry/src/main/ets/
├── entryability/EntryAbility.ets   # 启动：初始化 DB / 会话 / 主题，再加载首页
├── pages/                          # 路由级页面
│   ├── Index.ets                   #   启动页：按登录态分流到登录或主页
│   ├── LoginPage / RegisterPage    #   登录 / 注册
│   └── MainPage.ets                #   底部 5 Tab 容器
├── view/                           # Tab 内容与二级页面
│   ├── home/HomeTab                #   今日待办
│   ├── pets/{PetListTab,PetDetailPage,PetEditPage}
│   ├── calendar/CalendarTab        #   日历 + 提醒
│   ├── stats/StatsTab              #   统计仪表盘
│   ├── mine/MineTab                #   账户 / 主题 / 语言 / 退出
│   ├── logs/{Weight,Feed,Substrate,Molt,Env}LogPage
│   └── album/AlbumPage             #   成长相册
├── components/                     # 通用组件（PetCard / WeightChart / BarChart / …）
├── model/                          # 实体类（Pet / FeedLog / … / Urgency）
├── repository/                     # 仓储层（Database + 各表 Repository）
├── service/                        # 业务服务（Pet/Auth/Schedule/Stats/Reminder/Theme/Locale/Session/Seed）
├── utils/                          # 工具（DateUtil / Validator / Hash / I18n / Result / Logger）
└── constants/                      # 路由与设计令牌常量
```

**分层**：`UI (pages/view/components)` → `service` → `repository` → `relationalStore`。
UI 不直接接触数据库；数据层藏在仓储接口后，日后可无缝替换为后端 API。

---

## 🗃️ 数据模型（8 张表）

`user`、`pet`、`feed_log`、`weight_log`、`substrate_log`、`molt_log`、`env_log`、`photo`。
所有记录表均带 `pet_id` 外键；查询按 `user_id` 隔离，多用户数据互不可见。

---

## 🔁 核心逻辑：动态排程

复刻参考项目的核心思想——**下一次计划日期 = 实际打卡日期 + 间隔天数**：

```
登记一次喂食于 D  ⇒  next_feed_date = D + feed_interval
```

漏打卡的天数会随下次打卡自动纠偏，不会堆积欠账。紧急度由下次日期相对今天计算：
**今日（橙）/ 逾期（红）/ 未来（绿）**。

---

## 🌐 国际化与主题

- 字符串资源：`resources/base`（中文，默认回退）+ `resources/en_US`（英文）。
- 校验 / 服务层返回**资源键名**，页面经 `I18n.t(getContext(this), key)` 解析为当前语言。
- 在「我的」页可一键切换 中文 / English、浅色 / 深色，均持久化。

---

## 🚀 构建与运行

### 用 DevEco Studio（推荐）
1. 用 DevEco Studio 打开本工程
2. 连接模拟器或真机
3. 点击 **Run**，注册一个账号即可（首次注册会自动写入 2 只演示爬宠 + 历史数据）

### 命令行构建（仅校验编译 / 打包 HAP）
```powershell
$env:NODE_HOME = "<DevEco>\tools\node"
$env:DEVECO_SDK_HOME = "<DevEco>\sdk"
& "<DevEco>\tools\hvigor\bin\hvigorw.bat" --no-daemon assembleHap
```
> 调试包未配置签名，出现 `skip sign` 警告属正常现象。

---

## 🧪 测试

纯逻辑单元测试位于 `entry/src/test/LocalUnit.test.ets`，覆盖：
- `DateUtil`（日期格式化 / 加减 / 跨月 / 校验）
- `ScheduleService`（动态排程日期推算）
- `Validator`（用户名 / 密码 / 间隔 / 正数校验）

在 DevEco 中右键运行测试，或使用其测试运行器执行。

---

## 📌 说明

- 本仓库为**前端**实现，数据完全本地化、自包含，可直接运行演示。
- 通知提醒首次使用需在系统弹窗中允许通知权限。
- 演示数据：注册新账号后自动生成「斑斑（豹纹守宫）」与「小绿（鬃狮蜥）」两只示例宠物。
