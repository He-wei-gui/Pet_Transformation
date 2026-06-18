# 蜕变记 · Pet Transform 🦎

> 一款基于 **HarmonyOS（ArkTS / ArkUI）** 的爬宠（守宫、蜥蜴、蛇等）成长记录应用。
> 采用**在线优先的混合架构**：核心数据存云端 PHP 后端，多端（鸿蒙 App / 微信小程序）共享同一份数据；后端暂未覆盖的模块（蜕皮 / 环境 / 待办 / 视频）继续存本地 SQLite。

应用名「蜕变记」取自爬宠 **蜕**皮、成**变**长、记**记**录 —— 用心记录每一次蜕变。

---

## ✨ 功能特性

| 模块 | 说明 |
|------|------|
| 🔐 账号体系 | 账号密码注册/登录；**邮箱验证码注册**；**邮箱找回密码**；密码服务端 `password_hash` 存储；JWT 会话持久化 |
| 🏠 今日待办 | 聚合所有宠物的喂食/换料任务，按 **逾期 → 今日 → 未来** 排序，三色紧急度标签 |
| 🖼️ 成长瞬间 | 主页顶部**自动轮播**名下宠物的最新相册照片，点击进入相册大图查看 |
| 🦎 宠物管理 | 列表 / 详情 / 新增 / 编辑 / 删除（云端级联删记录）；头像支持 **emoji 或上传自定义照片** |
| ⚖️ 体重记录 | 录入称重，**Canvas 手绘体重趋势曲线** |
| 🍽️ 喂食 / 🪵 换料 | 打卡即按"实际打卡日 + 间隔"**动态重算下次日期**（核心业务逻辑） |
| 🐍 蜕皮 / 🌡️ 环境 | 蜕皮状态时间线；温度/湿度/UVB 记录 + 温度趋势曲线（本地存储） |
| 📷 成长相册 | 系统图库选图 → 上传云端 → 记录体长/说明，网格展示；**生化危机式高清查看器**（双指缩放 + 拖动 + 双击复位） |
| 🎬 成长视频 | 本地视频：选取 → 复制进沙箱 → 内置 `Video` 组件播放（不上云，本机可见） |
| 📊 数据统计 | 概览卡片 + 近 7 天喂食柱状图 |
| 🌐 国际化 | 应用内一键切换 **中文 / English** |
| 🌙 主题 | **浅色 / 深色** 双主题，持久化 |

---

## 🧱 技术栈

- **语言 / 框架**：ArkTS、ArkUI（声明式 `@Component` V1 + `@State/@Prop/@Watch` + `AppStorage`）
- **目标平台**：HarmonyOS API 22（6.0.2），phone，包名 `com.lysyminger.Pet_Transform`
- **网络**：`@kit.NetworkKit`（http；REST 调用 + 手拼 multipart 上传图片；TLS 由系统 CA 校验）
- **本地存储**：`@kit.ArkData`（`relationalStore` 本地 4 表 + `preferences` 会话/设置）
- **媒体**：`@kit.MediaLibraryKit`（`PhotoViewPicker` 选图/选视频）+ `@kit.CoreFileKit`（沙箱文件读写）
- **图表**：原生 `Canvas` 手绘（无第三方图表库）
- **后端**：PHP（前端控制器路由 + PDO/MySQL + JWT HS256 + `password_hash`），部署于阿里云，宝塔面板
- **邮件**：服务端零依赖 SMTP（`stream_socket_client` SSL，QQ 邮箱 465），发注册/找回验证码

> 无任何第三方运行时依赖，仅用 HarmonyOS 系统 Kit。

---

## 🏛️ 架构：在线优先的混合分层

```
UI (pages / view / components)
        │
     service                      ← 业务逻辑（Auth / Pet / Schedule / Stats / Session …）
        │
   repository                     ← 仓储层，方法名与数据源无关
     ├── ApiClient → 云端 REST    （pet / feed / weight / substrate / user / photo）
     └── relationalStore (SQLite) （molt / env / todo / video）
```

- **UI 永不直接碰数据源**：每个 `*Repository` 暴露相同方法名，无论它走云端还是本地 DB，故 service/UI 与数据源解耦。
- **标识符全为字符串**：云端主键是 32 位 hex `_id` / `openid`；本地附属表保留自增数字 `id`，但 `pet_id`/`user_id` 外键为字符串（TEXT）。
- **`ApiClient`** 统一封装 `get/post/put/del`，自动附 `Authorization: Bearer <token>`，返回 `Result<T>`；401 清会话，4xx 透传后端中文消息，5xx 兜底。
- **用户隔离**由后端按 token 的 `openid` 强制；删宠物时云端级联删记录，本地附属记录在 `PetService.deletePet` 清理。

---

## 🗂️ 目录结构

```
entry/src/main/ets/
├── entryability/EntryAbility.ets   # 启动：Database.init → SessionStore → Theme，再加载 Index
├── pages/
│   ├── Index.ets                   #   按 openid 是否为空分流到登录/主页
│   ├── LoginPage / RegisterPage    #   登录 / 注册（注册含邮箱验证码）
│   ├── ForgotPasswordPage.ets      #   邮箱找回密码
│   └── MainPage.ets                #   底部 Tab 容器
├── view/
│   ├── home/HomeTab                #   今日待办 + 成长瞬间轮播
│   ├── pets/{PetListTab,PetDetailPage,PetEditPage}
│   ├── mine/{MineTab,ProfilePage}  #   账户 / 编辑资料（昵称/头像/邮箱）/ 主题 / 语言
│   ├── logs/{Weight,Feed,Substrate,Molt,Env}LogPage
│   ├── album/AlbumPage             #   云端相册 + 高清查看器
│   └── video/VideoPage             #   本地成长视频
├── components/                     # 通用组件（PetAvatar / EmailCodeField / 图表 …）
├── model/                          # 实体类
├── repository/                     # 云端仓储 + 本地仓储 + Database
├── service/                        # ApiClient / AuthService / PetService / ScheduleService …
├── utils/                          # DateUtil / Validator / I18n / Result / Logger / Dialogs
└── constants/                      # RouteConstants / StorageKeys / ApiConfig / Theme

server/                             # PHP 后端（与微信小程序共享同一份）
├── index.php                       # 前端控制器 + 路由表 + 公开白名单
├── routes/{auth,user,pets,feed,weight,substrate,photos,...}.php
├── lib/{db,auth,response,mailer}.php
└── sql/                            # 迁移脚本
```

---

## 🔁 核心逻辑：动态排程

**下一次计划日期 = 实际打卡日期 + 间隔天数**（`ScheduleService.nextFeedDate` / `nextSubstrateDate`）：

```
登记一次喂食于 D  ⇒  next_feed_date = D + feed_interval
```

漏打卡不会堆积欠账，下次打卡自动纠偏。紧急度由下次日期相对今天计算：**今日（橙）/ 逾期（红）/ 未来（绿）**。

---

## 📧 邮箱验证码 / 找回密码（增量、不影响小程序）

- 后端新增可空 `email` 列 + `email_codes` 表 + `/auth/send-code`、`/auth/reset-password` 路由（小程序从不调用）。
- 验证码服务端生成、存储、校验，60 秒限频、10 分钟有效、一次性防重放。
- 发信走服务端零依赖 SMTP（授权码只存服务器 `.env`，不进客户端、不进仓库）。
- 注册需邮箱验证；找回密码 = 用户名 + 邮箱匹配 + 验证码 → 重置 `password_hash`。

---

## 🚀 构建与运行

### DevEco Studio（推荐）
打开工程 → Sync → 连接模拟器/真机 → Run。用邮箱注册账号即可（需联网访问 `api.lysyminger.online`）。

### 命令行（仅校验编译 / 打包 HAP，调试包未签名）
```powershell
$env:NODE_HOME = "<DevEco>\tools\node"
$env:DEVECO_SDK_HOME = "<DevEco>\sdk"
& "<DevEco>\tools\hvigor\bin\hvigorw.bat" --no-daemon assembleHap
```

---

## 🧪 测试

纯逻辑单元测试 `entry/src/test/LocalUnit.test.ets`，覆盖 `DateUtil` / `ScheduleService` / `Validator`。DevEco 中右键运行。

---

## 📚 文档

- [项目总结](docs/项目总结.md)
- [项目详细分析](docs/项目详细分析.md)
- [答辩问答（一问一答）](docs/答辩问答.md)
