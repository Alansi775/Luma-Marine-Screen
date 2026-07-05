import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'thumbnail_cache.g.dart';

/// In-memory, app-session-lifetime cache of resolved thumbnail download
/// URLs, keyed by videoId — avoids re-calling `getDownloadURL()` (a
/// network round-trip) every time a playlist screen re-renders. The
/// actual image bytes are cached by Flutter's own `Image.network`/
/// `ImageCache` once a URL is known, so this only needs to remember the
/// URL itself. Keyed by videoId (not entryId) so moving a video between
/// playlists keeps its cached URL, and one new video never touches the
/// cache entries for videos already resolved.
class ThumbnailCache {
  final Map<String, String> _urls = {};

  String? get(String videoId) => _urls[videoId];

  void put(String videoId, String url) => _urls[videoId] = url;

  void evict(String videoId) => _urls.remove(videoId);
}

@Riverpod(keepAlive: true)
ThumbnailCache thumbnailCache(Ref ref) => ThumbnailCache();
