import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'thumbnail_cache.g.dart';

/// In-memory, app-session-lifetime cache of generated video thumbnail
/// PNGs, keyed by videoId. Generating a thumbnail means spinning up a
/// real `VideoPlayerController` (a full decoder) just to grab its first
/// frame — fine once, wasteful to repeat every time the admin re-opens a
/// playlist they were just looking at. Keyed by videoId (not entryId) so
/// moving a video between playlists doesn't lose its cached thumbnail,
/// and adding one new video never touches the cache entries for videos
/// already generated.
class ThumbnailCache {
  final Map<String, Uint8List> _bytes = {};

  Uint8List? get(String videoId) => _bytes[videoId];

  void put(String videoId, Uint8List bytes) => _bytes[videoId] = bytes;

  void evict(String videoId) => _bytes.remove(videoId);
}

@Riverpod(keepAlive: true)
ThumbnailCache thumbnailCache(Ref ref) => ThumbnailCache();
