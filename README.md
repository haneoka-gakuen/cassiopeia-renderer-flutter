# Cassiopeia renderer for Flutter

An independent Flutter rendering backend for Cassiopeia. `CassiopeiaRenderSession` takes a generic draw graph and an asset loader, then submits frames and manages image resources through the shared GPU kernel.

`overview.dart` draws a flat chart view panel by panel from notes, curves and atlas geometry produced by a format plugin. The session runtime owns judgement and the timeline, game plugins own lanes, notes, HUD and effect data, and the host supplies media and input.

Run `flutter pub get` and `flutter analyze` from the repository root. Haneoka's Linux Flutter AOT build uses this source and has run it with real charts, normal lives and gekiso performances.
