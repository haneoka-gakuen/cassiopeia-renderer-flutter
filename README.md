# Cassiopeia renderer for Flutter

Cassiopeia 的独立 Flutter 渲染后端。`CassiopeiaRenderSession` 接收通用绘制图与资源加载器，复用共享 GPU kernel 提交帧和管理图片资源。

`overview.dart` 提供按可见面板绘制的平面谱面视图，接收格式插件生成的音符、曲线和图集几何。会话运行时负责判定与时间线，游戏插件负责轨道、音符、HUD和特效数据，宿主组合媒体与输入。

运行 `flutter pub get` 与 `flutter analyze`。此源版本已进入 Haneoka 的 Linux Flutter AOT 构建，并在真实谱面、普通Live和激奏演出中运行。
