import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps an autoDispose provider's answer for [duration] after the last
/// screen stops watching it.
///
/// What is let go when its screen closes (6 Nov) was read again on every
/// quick switch between tabs — the home page's badges each time Home came
/// back, News's category links each time News opened (24 Nov). Kept a short
/// while, a quick return shows what was just read; after that it is let go
/// and read fresh as before. An `invalidate` still reads it again at once.
extension CacheFor on Ref<Object?> {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
