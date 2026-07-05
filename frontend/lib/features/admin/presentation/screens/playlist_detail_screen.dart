import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

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
      setState(() => _message = 'Node synced: "${file.name}".');
    } on NetworkException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _renamePlaylist(AdminPlaylist playlist) async {
    final name = await _promptForText(title: 'Rename Sequence', initialValue: playlist.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistManagementRepositoryProvider).renamePlaylist(playlist.id, name.trim());
  }

  Future<void> _renameVideo(PlaylistVideoItem item) async {
    final name = await _promptForText(title: 'Rename Media', initialValue: item.name);
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
        content: const Text('No alternate arrays available for transfer.'),
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
                    'TRANSFER TO',
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
                    AdminPillButton(label: 'Cancel', filled: false, onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    AdminPillButton(label: 'Save', onPressed: () => Navigator.pop(context, controller.text)),
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  String? _formatUploadedAt(DateTime? dt) {
    if (dt == null) return null;
    final local = dt.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${_months[local.month - 1]} ${local.day}, ${local.year} · $hour12:$minute $period';
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
                            playlist?.name ?? 'Loading Sequence...',
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
                              tooltip: 'Edit Sequence',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- Grid Area ---
                  Expanded(
                    child: entries.when(
                      loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
                      error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Data failure.\n$e'),
                      data: (items) => items.isEmpty
                          ? const EmptyState(
                              icon: Icons.movie_filter_outlined,
                              message: 'Sequence is empty.\nInject media below.',
                            )
                          : GridView.builder(
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
                                      child: LongPressDraggable<int>(
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
                                Text('TRANSMITTING', style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                                const SizedBox(height: 4),
                                Text('Synchronizing node data...', style: TextStyle(color: c.textDim, fontSize: 14)),
                              ],
                            ),
                          ),
                        ] else ...[
                          if (_message != null)
                            Expanded(child: Text(_message!, style: TextStyle(color: c.textDim, fontSize: 14)))
                          else
                            const Spacer(),
                          AdminPillButton(label: 'Inject Media', icon: Icons.upload_rounded, onPressed: _pickAndUpload),
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
}

/// One video's card: a cached thumbnail of its actual first frame, its
/// duration as a corner badge, its name, upload date/time, and a glass
/// menu — the whole card is the drag handle (long-press to pick it up),
/// so there's no separate drag-indicator icon to get wrong.
class _VideoGridCell extends StatelessWidget {
  const _VideoGridCell({
    super.key,
    required this.item,
    required this.durationLabel,
    required this.uploadedAtLabel,
    required this.onRename,
    required this.onMove,
    required this.onRemove,
  });

  final PlaylistVideoItem item;
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
                  child: _VideoThumbnail(videoId: item.videoId, storagePath: item.storagePath),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GlassMenuButton(
                    items: [
                      GlassMenuItem(label: 'Rename', icon: Icons.edit_outlined, onTap: onRename),
                      GlassMenuItem(label: 'Transfer…', icon: Icons.drive_file_move_outline, onTap: onMove),
                      GlassMenuItem(label: 'Extract', icon: Icons.delete_outline, danger: true, onTap: onRemove),
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

/// Shows the video's actual first frame — cached after the first
/// generation (see `ThumbnailCache`), so re-opening a playlist never
/// re-pays the cost of spinning up a decoder per video again.
///
/// Generation path (cache miss only): create a `VideoPlayerController`,
/// let it buffer frame 0, render it once into an off-tree
/// `RepaintBoundary`, capture that as a PNG, cache the bytes, then
/// immediately dispose the controller. Holding one real decoder per
/// grid cell indefinitely — which is what this used to do — is exactly
/// the kind of resource pressure the signage side's playback watchdog
/// had to be built to survive; there is no reason the admin panel
/// should create the same problem for itself just to show a preview.
class _VideoThumbnail extends ConsumerStatefulWidget {
  const _VideoThumbnail({required this.videoId, required this.storagePath});

  final String videoId;
  final String? storagePath;

  @override
  ConsumerState<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends ConsumerState<_VideoThumbnail> {
  final _boundaryKey = GlobalKey();
  VideoPlayerController? _controller;
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final cached = ref.read(thumbnailCacheProvider).get(widget.videoId);
    if (cached != null) {
      _bytes = cached;
    } else {
      _generate();
    }
  }

  Future<void> _generate() async {
    final path = widget.storagePath;
    if (path == null) {
      setState(() => _failed = true);
      return;
    }
    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        unawaited(controller.dispose());
        return;
      }
      setState(() => _controller = controller);
      // Two frames plus a short delay: the first post-frame callback can
      // fire before the video texture has actually painted anything
      // (a real gotcha with hardware-texture-backed video on web), which
      // would capture a blank frame and cache it forever.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) await _capture();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _capture() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _failed = true);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();
      ref.read(thumbnailCacheProvider).put(widget.videoId, bytes);

      final controller = _controller;
      _controller = null;
      unawaited(controller?.dispose());

      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    final bytes = _bytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }

    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      // Rendered at real size so the captured PNG matches what a viewer
      // would actually see, not a scaled-down preview.
      return RepaintBoundary(
        key: _boundaryKey,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
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
