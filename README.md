# 认认 chushi

给 1—3 岁孩子用的认知启蒙 App：一张图，一个词，点一下就能听见爸爸妈妈的声音。

第一期是**纯工具**形态：不注册、不登录、不联网，没有儿童类别，也没有幼儿端 / 家长端两套界面——孩子看到的就是一屏卡片。

- 需求文档（唯一准绳）：[认认 PRD v1.0](https://feishu.doubao.com/docx/MwQvdFWVOoywG3xLyPqcyXqAnfe)
- 形态：Flutter 单代码库，一套代码出 iOS + Android
- 版本固定：Flutter **3.47.5**（Dart 3.13.4，stable），通过 `.fvmrc` 交给 fvm 管理
- 系统门槛：iOS 15+，Android 8.0+（minSdk 26）

## 功能

1. **首页**：奶油底 + 一屏大卡片，按「动物 / 食物 / 日常用品 / 家人 / 我的」分类。点卡片进全屏播放层，进来就发声；左右滑换卡，下滑关闭，8 秒无操作自动退出。
2. **自定义**：选图（拍照或相册，自动压到长边 1200 / JPEG 80）→ 写词 → 录音（1—15 秒，16 kHz 单声道 AAC）或留空走系统朗读 → 试听 → 保存。没有词名也没有录音的卡片不允许保存。
3. **设置（家长入口）**：右上角 40 像素、贴边、无文字图标；**长按 2 秒 + 一道两位数加法**才进得去，通过后 10 分钟内免验证。设置里三组：卡片管理（拖拽排序 / 改 / 删，删除二次确认）、数据与迁移、通用设置（显示文字、语速、休息提醒、系统朗读状态）。
4. **跨设备**：没有账号，靠 `.renren` 作品包——`manifest.json` + `images/` + `audio/` + `cover.jpg` 打成 zip，经系统分享面板发出，另一台设备点开即导入。同名卡片保留两份并标注「副本」。设置页常驻上次备份时间，超过 30 天提示。

## 目录

```
lib/
  app/theme.dart            奶油底 + 珊瑚橘单主色，大圆角
  data/                     models / builtin_cards(40 张) / database(sqflite) / repository
  services/                 voice_player(录音优先 TTS 兜底) / recorder / package / photo
  state/app_state.dart      设置项、门禁、备份时间、卡片增删
  ui/                       home / playback_overlay / settings_entry / gate_dialog
                            settings / card_manage / card_edit / migration
```

## 本地运行

项目用 [fvm](https://fvm.app) 固定版本，先装好 fvm，然后：

```bash
fvm install               # 按 .fvmrc 装 Flutter 3.47.5
fvm use 3.47.5            # 已在项目里执行过，新克隆只需 fvm install
fvm flutter pub get       # pubspec.lock 未入库，会重新解析依赖
fvm flutter analyze       # 当前 0 issue
fvm flutter test
fvm flutter run
```

不用 fvm 时，确认本机 `flutter --version` 是 3.47.5，直接跑 `flutter pub get / analyze / test / run` 即可。

## 已验证状态

- Flutter 3.47.5（Dart 3.13.4）下 `flutter analyze`：0 issue
- `flutter test`：5 条用例全过（内置卡 40 张与分类、哑卡不发声、录音卡识别、主题配色一致）
- `flutter build apk --debug` / `--release`：均可成功出包，产物在 `build/app/outputs/flutter-apk/`
- iOS 侧只完成了工程配置（Bundle ID `com.renren.chushi`、iOS 15 部署目标、四段权限文案、`.renren` 类型注册），**尚未在本机跑过 `pod install` 与真机编译**

## 现状与待办

- 内置 40 张卡片的图片位**暂用大号 emoji 承载**（体积小、跨端一致），后续换成正式插画只需改 `builtin_cards.dart` 的数据。
- `.renren` 的系统级「点开即导入」已在 Android Manifest 与 iOS `Info.plist` 注册类型，Dart 侧的 intent / openURL 回调还没接，第一期先用「从文件导入」按钮兜住。
- 平板：竖屏 2 列、横屏 4 列；iPad 与 10 英寸 Android 平板需真机验证。
- 新克隆仓库后如果缺少 `android/gradle/wrapper/gradle-wrapper.jar` 与 iOS 图标，跑一次 `flutter create --platforms=android,ios .` 就能补齐本地脚手架（本仓库以纯文本形式维护，二进制资源不进版本控制）。
