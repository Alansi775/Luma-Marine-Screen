import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/admin_playlist.dart';
import '../../domain/entities/playlist_video_item.dart';
import '../providers/admin_providers.dart';
import '../providers/thumbnail_cache.dart';
import '../theme/admin_design_kit.dart';

/// One playlist's contents: reorder (drag any card onto another), rename
/// or remove videos, move a video to a different playlist, and upload
/// new videos directly into this playlist.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  bool _isUploading = false;
  double _progress = 0;
  String? _message;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;

    setState(() {
      _isUploading = true;
      _progress = 0;
      _message = null;
    });

    try {
      await ref.read(videoUploadServiceProvider).uploadVideo(
            bytes: file!.bytes!,
            fileName: file.name,
            playlistId: widget.playlistId,
            onProgress: (p) => setState(() => _progress = p),
          );
      setState(() => _message = 'Düğüm senkronize edildi: "${file.name}".');
    } on NetworkException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _renamePlaylist(AdminPlaylist playlist) async {
    final name = await _promptForText(title: 'Diziyi Yeniden Adlandır', initialValue: playlist.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistManagementRepositoryProvider).renamePlaylist(playlist.id, name.trim());
  }

  Future<void> _renameVideo(PlaylistVideoItem item) async {
    final name = await _promptForText(title: 'Medyayı Yeniden Adlandır', initialValue: item.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistManagementRepositoryProvider).renameVideo(item.videoId, name.trim());
    ref.invalidate(playlistEntriesProvider(widget.playlistId));
  }

  Future<void> _removeVideo(PlaylistVideoItem item) async {
    await ref.read(playlistManagementRepositoryProvider).removeVideoFromPlaylist(
          playlistId: widget.playlistId,
          entryId: item.entryId,
          videoId: item.videoId,
        );
    // The video (and its Storage file) may just have been deleted for
    // good — see removeVideoFromPlaylist's orphan cleanup — so its
    // cached thumbnail would otherwise sit around forever pointing at
    // nothing useful.
    ref.read(thumbnailCacheProvider).evict(item.videoId);
  }

  Future<void> _moveVideo(PlaylistVideoItem item) async {
    final playlists = ref.read(adminPlaylistsProvider).value ?? const <AdminPlaylist>[];
    final candidates = playlists.where((p) => p.id != widget.playlistId).toList();
    final c = AdminColors.of(context);
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Aktarım için uygun başka liste yok.'),
        backgroundColor: c.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final target = await showDialog<AdminPlaylist>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          borderRadius: 24,
          elevated: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Text(
                    'ŞURAYA AKTAR',
                    style: TextStyle(color: c.textDim, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ),
                for (final p in candidates)
                  InkWell(
                    onTap: () => Navigator.pop(context, p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Text(p.name, style: TextStyle(color: c.textPrimary, fontSize: 16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (target == null) return;

    await ref.read(playlistManagementRepositoryProvider).moveVideoToPlaylist(
          fromPlaylistId: widget.playlistId,
          entryId: item.entryId,
          videoId: item.videoId,
          toPlaylistId: target.id,
        );
  }

  /// Drag-and-drop reorder: `toIndex` is the final slot the dragged card
  /// was dropped onto — a plain remove-then-insert, unlike
  /// `ReorderableListView`'s callback convention (which reports the
  /// pre-removal index and needs a -1 correction). There's no listview
  /// here anymore, so no correction is needed.
  Future<void> _reorder(List<PlaylistVideoItem> items, int fromIndex, int toIndex) async {
    final reordered = List.of(items);
    final moved = reordered.removeAt(fromIndex);
    reordered.insert(toIndex, moved);
    await ref
        .read(playlistManagementRepositoryProvider)
        .reorderEntries(widget.playlistId, reordered.map((e) => e.entryId).toList());
  }

  Future<String?> _promptForText({required String title, required String initialValue}) {
    final controller = TextEditingController(text: initialValue);
    final c = AdminColors.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          borderRadius: 32,
          elevated: true,
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                AdminTextField(
                  controller: controller,
                  autofocus: true,
                  onSubmitted: (value) => Navigator.pop(context, value),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AdminPillButton(label: 'İptal', filled: false, onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    AdminPillButton(label: 'Kaydet', onPressed: () => Navigator.pop(context, controller.text)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatDuration(int? seconds) {
    if (seconds == null) return null;
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara', //
  ];

  String? _formatUploadedAt(DateTime? dt) {
    if (dt == null) return null;
    final local = dt.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'ÖÖ' : 'ÖS';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month - 1]} ${local.year} · $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    final playlists = ref.watch(adminPlaylistsProvider).value ?? const <AdminPlaylist>[];
    final playlist = playlists.where((p) => p.id == widget.playlistId).firstOrNull;
    final entries = ref.watch(playlistEntriesProvider(widget.playlistId));

    return AdminTheme(
      child: Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          SafeArea(
            child: AdminPageWidth(
              child: Column(
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 40, 32),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: c.textDim,
                          splashRadius: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            playlist?.name ?? 'Dizi Yükleniyor...',
                            style: TextStyle(color: c.textPrimary, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -1),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (playlist != null)
                          Container(
                            decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(12)),
                            child: IconButton(
                              onPressed: () => _renamePlaylist(playlist),
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              color: c.textPrimary,
                              tooltip: 'Diziyi Düzenle',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- Grid Area ---
                  Expanded(
                    child: entries.when(
                      loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
                      error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Veri hatası.\n$e'),
                      data: (items) => items.isEmpty
                          ? const EmptyState(
                              icon: Icons.movie_filter_outlined,
                              message: 'Dizi boş.\nAşağıdan medya ekle.',
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (items.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.drag_indicator_rounded, size: 14, color: c.textDim),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Oynatma sırasını değiştirmek için kartları sürükleyip bırakın',
                                          style: TextStyle(color: c.textDim, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(child: _buildGrid(items)),
                              ],
                            ),
                    ),
                  ),

                  // --- Upload Action Bar ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                    child: Row(
                      children: [
                        if (_isUploading) ...[
                          LiquidUploadRing(progress: _progress, size: 56),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('AKTARILIYOR', style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                                const SizedBox(height: 4),
                                Text('Düğüm verisi senkronize ediliyor...', style: TextStyle(color: c.textDim, fontSize: 14)),
                              ],
                            ),
                          ),
                        ] else ...[
                          if (_message != null)
                            Expanded(child: Text(_message!, style: TextStyle(color: c.textDim, fontSize: 14)))
                          else
                            const Spacer(),
                          AdminPillButton(label: 'Medya Ekle', icon: Icons.upload_rounded, onPressed: _pickAndUpload),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading) UploadEdgeGlow(progress: _progress),
        ],
      ),
      ),
    );
  }

  Widget _buildGrid(List<PlaylistVideoItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 264,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final cell = _VideoGridCell(
          key: ValueKey('cell-${item.entryId}'),
          item: item,
          order: i + 1,
          durationLabel: _formatDuration(item.durationSeconds),
          uploadedAtLabel: _formatUploadedAt(item.uploadedAt),
          onRename: () => _renameVideo(item),
          onMove: () => _moveVideo(item),
          onRemove: () => _removeVideo(item),
        );
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != i,
          onAcceptWithDetails: (details) => _reorder(items, details.data, i),
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return AnimatedScale(
              scale: isDropTarget ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 120),
              // Plain Draggable (not LongPressDraggable): this is a
              // mouse-driven web admin panel, and requiring a
              // press-and-hold before a card can be dragged isn't an
              // obvious gesture there — a normal click-and-drag reads
              // immediately as "this is reorderable."
              child: Draggable<int>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(width: 260, height: 200, child: Opacity(opacity: 0.9, child: cell)),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: cell),
                child: cell,
              ),
            );
          },
        );
      },
    );
  }
}

/// One video's card: a cached thumbnail of its actual first frame, its
/// play order and duration as corner badges, its name, upload
/// date/time, and a glass menu — the whole card is the drag handle
/// (click and drag to pick it up), so there's no separate
/// drag-indicator icon to get wrong.
class _VideoGridCell extends StatelessWidget {
  const _VideoGridCell({
    super.key,
    required this.item,
    required this.order,
    required this.durationLabel,
    required this.uploadedAtLabel,
    required this.onRename,
    required this.onMove,
    required this.onRemove,
  });

  final PlaylistVideoItem item;
  final int order;
  final String? durationLabel;
  final String? uploadedAtLabel;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    return GlassPanel(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _VideoThumbnail(videoId: item.videoId, thumbnailPath: item.thumbnailPath),
                ),
                // The play order — the whole point of dragging these
                // cards around is to control this number, so it needs to
                // be immediately visible, not something the admin has to
                // infer from grid position alone.
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.background.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.hairlineBright, width: 0.8),
                    ),
                    child: Text(
                      '$order',
                      style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GlassMenuButton(
                    items: [
                      GlassMenuItem(label: 'Yeniden Adlandır', icon: Icons.edit_outlined, onTap: onRename),
                      GlassMenuItem(label: 'Aktar…', icon: Icons.drive_file_move_outline, onTap: onMove),
                      GlassMenuItem(label: 'Çıkar', icon: Icons.delete_outline, danger: true, onTap: onRemove),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 11, color: c.textDim),
                    const SizedBox(width: 5),
                    Expanded(
                      child: MonoLabel(uploadedAtLabel ?? '—', fontSize: 11),
                    ),
                    if (durationLabel != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.schedule_rounded, size: 11, color: c.textDim),
                      const SizedBox(width: 4),
                      MonoLabel(durationLabel!, fontSize: 11),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the video's server-generated thumbnail (see
/// backend/functions/index.js), resolved to a download URL once and
/// cached (see `ThumbnailCache`) so re-opening a playlist doesn't
/// re-fetch it.
///
/// This used to capture a frame client-side via a live
/// `VideoPlayerController` + `RepaintBoundary.toImage()`. That doesn't
/// work on Flutter Web: `video_player` there renders through a real
/// HTML `<video>` element composited outside Flutter's own canvas, so
/// `toImage()` can never see an actual frame — confirmed empirically
/// (every capture came back as a ~250-byte blank PNG, regardless of how
/// long it waited first). Generating the thumbnail server-side sidesteps
/// that entirely and scales the same at 3 videos or 3 million, since the
/// admin UI never touches a decoder at all — it just displays an image.
class _VideoThumbnail extends ConsumerStatefulWidget {
  const _VideoThumbnail({required this.videoId, required this.thumbnailPath});

  final String videoId;
  final String? thumbnailPath;

  @override
  ConsumerState<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends ConsumerState<_VideoThumbnail> {
  String? _url;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Firestore delivers the thumbnailPath a few seconds after upload,
    // once the Cloud Function finishes — this is what picks that up
    // without the admin needing to refresh anything.
    if (oldWidget.thumbnailPath != widget.thumbnailPath) {
      _url = null;
      _failed = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final path = widget.thumbnailPath;
    if (path == null) return;
    final cached = ref.read(thumbnailCacheProvider).get(widget.videoId);
    if (cached != null) {
      setState(() => _url = cached);
      return;
    }
    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      ref.read(thumbnailCacheProvider).put(widget.videoId, url);
      if (mounted) setState(() => _url = url);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    final url = _url;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: c.surfaceRaised,
          child: Center(child: Icon(Icons.movie_outlined, color: c.textDim, size: 28)),
        ),
      );
    }

    return ColoredBox(
      color: c.surfaceRaised,
      child: Center(
        child: _failed
            ? Icon(Icons.movie_outlined, color: c.textDim, size: 28)
            : SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.textDim),
              ),
      ),
    );
  }
}
