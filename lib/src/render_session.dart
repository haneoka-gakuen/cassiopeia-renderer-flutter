import 'package:render_kernel_flutter/render_kernel_flutter.dart';

final class CassiopeiaRenderSession extends RenderSession {
  CassiopeiaRenderSession({
    required super.renderer,
    required super.fetch,
    super.reuseDecodedImages,
    super.retainDecodedImageMipmaps = false,
  });
}
