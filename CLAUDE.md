# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

「蜕变记 / Pet Transform」— a HarmonyOS (ArkTS / ArkUI) growth-tracking app for reptiles (geckos, lizards, snakes). Self-contained front-end: all data is stored locally, no backend. Target: HarmonyOS API 22 (6.0.2), `phone` device. Bundle: `com.lysyminger.Pet_Transform`.

## Build / Run / Test

Primary workflow is **DevEco Studio**: open the project, let it Sync (regenerates `hvigorw`, resolves the SDK), connect an emulator/device, and Run. Registering a new account auto-seeds two demo pets with history (`SeedService`).

Command-line build (compile-check / package HAP only — debug build is unsigned, `skip sign` warnings are normal):
```powershell
$env:NODE_HOME = "<DevEco>\tools\node"
$env:DEVECO_SDK_HOME = "<DevEco>\sdk"
& "<DevEco>\tools\hvigor\bin\hvigorw.bat" --no-daemon assembleHap
```

Tests use `@ohos/hypium`. Pure-logic unit tests live in `entry/src/test/LocalUnit.test.ets` (covers `DateUtil`, `ScheduleService`, `Validator`); instrumented tests in `entry/src/ohosTest/`. Run via DevEco's test runner (right-click the test file/case).

Lint config is `code-linter.json5` (ESLint-based, `@performance` + `@typescript-eslint` + `@security` rules). Password hashing now happens server-side (PHP `password_hash` in `server/routes/auth.php`); the legacy `utils/Hash.ets` (CryptoArchitectureKit SHA256) is unused after the cloud migration.

Headless compile-check (used during development) works via the DevEco-bundled toolchain: set `DEVECO_SDK_HOME` to `<DevEco>/sdk` and run `node <DevEco>/tools/hvigor/bin/hvigorw.js --no-daemon assembleHap` from the project root.

### Stale-cache gotcha
After large changes to resource files (`resources/.../element/*.json`), the hvigor **incremental** build can keep a stale resource index and report `Unknown resource name 'xxx'` for resources that actually exist. Fix: kill stuck `daemon-process-boot-script` node processes, delete `entry/.preview`, `entry/build`, `.hvigor/cache`, `.hvigor/outputs`, and `~/.hvigor/daemon/cache/daemon-sec.json`, then Build → Clean Project and rerun.

## Architecture

> **Hybrid online-first architecture.** Core data (user / pet / feed / weight / substrate) lives in the cloud PHP backend (`server/`, deployed at `https://api.lysyminger.online/api`); the app calls it online-first. Only modules the backend doesn't have yet — **molt / env / photo / todo** — remain in local SQLite. See `server/` and the merge plan for the API contract.

Strict layering, all under `entry/src/main/ets/`:

```
UI (pages / view / components)  →  service  →  repository  →  ┬─ ApiClient → cloud REST   (pet/feed/weight/substrate/user)
                                                              └─ relationalStore (SQLite) (molt/env/photo/todo)
```

UI never touches the data source directly; each `*Repository` exposes the same method names regardless of whether it talks to the cloud or local DB, so service/UI code is source-agnostic.

- **Identifiers are strings everywhere.** Cloud primary keys are 32-hex `_id` / `openid`; all model `id`/`userId`/`petId` and the `AppStorage` keys `SESSION_USER_ID` (=openid) and `CURRENT_PET_ID` are `string` (empty string = none). Local-only tables (molt/env/photo/todo) keep an auto-increment numeric `id` but a **string `pet_id`/`user_id`** foreign key (TEXT column).
- **`service/ApiClient.ets`** — the cloud HTTP layer (`@kit.NetworkKit` http). `get/post/put/del` auto-attach `Authorization: Bearer <token>` and return `Result<T>`; `unwrap()` throws a messageKey-carrying error for repositories. `postPublic()` is for login/register (401 passes through the backend message instead of triggering session-expiry). Config in `constants/ApiConfig.ets`.
- **`repository/`** — cloud repos (`PetRepository`, `FeedLogRepository`, `WeightLogRepository`, `SubstrateLogRepository`, `UserRepository`) call `ApiClient` and map cloud JSON fields to models (e.g. `birthDate↔arrivalDate`, `date↔feed_date/record_date/change_date`, `substrateType↔sub_type`). Local repos (`MoltLog/EnvLog/Photo/Todo`) still use `Database.ets` (a singleton `RdbStore`, `init()` before use in `EntryAbility.onWindowStageCreate`, now only 4 tables). User isolation is enforced server-side by the token's `openid`; deleting a pet cascades cloud records on the backend, while local attached records are cleared in `PetService.deletePet`.
- **`service/`** — business logic. Key services: `AuthService` (account/password register/login against `/auth/register` & `/auth/login-app`, persists openid+token), `ScheduleService` (see core logic below), `SessionStore` (openid+nickname+token in `preferences`, mirrored into `AppStorage`), `ThemeService` / `LocaleService` (persisted light/dark + zh/en), `StatsService`, `ReminderService` (local notifications via `@kit.NotificationKit`). `SeedService` is a disabled no-op (demo data no longer seeded locally).
- **`model/`** — plain entity classes (constructor-positional fields, e.g. `Pet`, `FeedLog`, `Urgency`).
- **`pages/`** — router-level pages registered in `resources/base/profile/main_pages.json`. `view/` holds tab content + secondary pages, `components/` holds reusable UI.

### Startup flow
`EntryAbility.onWindowStageCreate` awaits `Database.init` → `SessionStore.init` → `SessionStore.restoreToAppStorage` → `ThemeService.init`, *then* loads `pages/Index`. `Index` reads `StorageKeys.SESSION_USER_ID` from `AppStorage` and routes to `MainPage` (logged in) or `LoginPage`.

### Core business logic: dynamic scheduling
`next planned date = actual check-in date + interval days` (`ScheduleService.nextFeedDate` / `nextSubstrateDate` via `DateUtil.addDays`). Missed days self-correct on the next check-in instead of piling up debt. Urgency (today/overdue/upcoming → orange/red/green) is computed from the next date relative to today.

## Conventions

- **Routing**: navigate with `@ohos.router` using the URL constants in `constants/RouteConstants.ets`; every routable URL must also be listed in `main_pages.json`. Cross-page/persisted keys live in `StorageKeys` (same file) — don't hard-code these strings.
- **Result type**: service/repository operations return `Result<T>` (`Result.ok` / `Result.fail`) instead of throwing to the UI.
- **i18n**: validators and services return **resource key names**, not literal text. Pages resolve them to the current language via `I18n.t(getContext(this), key)`. Strings live in `resources/base` (zh, default fallback) and `resources/en_US` (en) — keep both in sync when adding strings. Same for `resources/base` vs `resources/dark` color sets.
- **Design tokens**: spacing/font/radius/color come from `resources/base/element/{float,color}.json` referenced as `$r('app.float.…')` / `$r('app.color.…')`; see also `constants/Theme.ets`. Don't hard-code magic numbers/colors.
- **ArkUI**: declarative components (`@Component` V1 + `@State/@Prop/@Watch` + `AppStorage`). Charts are hand-drawn on native `Canvas` (no third-party chart lib). No third-party runtime dependencies — only HarmonyOS system Kits.
