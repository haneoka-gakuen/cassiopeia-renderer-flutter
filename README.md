# Cassiopeia renderer for Flutter

Flutter rendering backend and chart overview for the [Cassiopeia](https://github.com/haneoka-gakuen/cassiopeia) rhythm-game engine.

`CassiopeiaRenderSession` takes a generic draw graph and an asset loader, then submits frames and manages image resources through [`render-kernel-flutter`](https://github.com/haneoka-gakuen/render-kernel-flutter). `overview.dart` draws a flat chart view from notes, curves and atlas geometry produced by a format plugin. The session runtime owns judgement and the timeline, and game plugins own lanes and notes.

## Usage

Add the package as a Git dependency and create a `CassiopeiaRenderSession`.

## Development

```sh
flutter pub get
flutter analyze
```

## License

[MPL-2.0](LICENSE).
