import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/admin_playlist.dart';
import '../../domain/entities/playlist_video_item.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_design_kit.dart';

/// One playlist's contents: reorder, rename or remove videos, move a
/// video to a different playlist, and upload new videos directly into
/// this playlist. There is no "upload" entry point anywhere else in the
/// admin panel — a video always belongs to some playlist from the moment
/// it's uploaded.
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
      setState(() => _message = 'Uploaded "${file.name}".');
    } on NetworkException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _renamePlaylist(AdminPlaylist playlist) async {
    final name = await _promptForText(title: 'Rename Playlist', initialValue: playlist.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(playlistManagementRepositoryProvider).renamePlaylist(playlist.id, name.trim());
  }

  Future<void> _renameVideo(PlaylistVideoItem item) async {
    final name = await _promptForText(title: 'Rename Video', initialValue: item.name);
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
  }

  Future<void> _moveVideo(PlaylistVideoItem item) async {
    final playlists = ref.read(adminPlaylistsProvider).value ?? const <AdminPlaylist>[];
    final candidates = playlists.where((p) => p.id != widget.playlistId).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No other playlists to move this into.')));
      return;
    }

    final target = await showDialog<AdminPlaylist>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          borderRadius: 28,
          elevated: true,
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'MOVE TO PLAYLIST',
                    style: TextStyle(color: AdminPalette.textDim, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
                ),
                for (final p in candidates)
                  ListTile(
                    title: Text(p.name, style: const TextStyle(color: AdminPalette.textPrimary)),
                    onTap: () => Navigator.pop(context, p),
                  ),
                const SizedBox(height: 8),
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

  Future<void> _reorder(List<PlaylistVideoItem> items, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List.of(items);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await ref
        .read(playlistManagementRepositoryProvider)
        .reorderEntries(widget.playlistId, reordered.map((e) => e.entryId).toList());
  }

  Future<String?> _promptForText({required String title, required String initialValue}) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          borderRadius: 28,
          elevated: true,
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AdminPalette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AdminPalette.hairline),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: AdminPalette.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (value) => Navigator.pop(context, value),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: AdminPalette.textPrimary, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('SAVE', style: TextStyle(color: AdminPalette.accent, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '—:—';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(adminPlaylistsProvider).value ?? const <AdminPlaylist>[];
    final playlist = playlists.where((p) => p.id == widget.playlistId).firstOrNull;
    final entries = ref.watch(playlistEntriesProvider(widget.playlistId));

    return Scaffold(
      backgroundColor: AdminPalette.black,
      body: Stack(
        children: [
          SafeArea(
            child: AdminPageWidth(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 28, 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          color: AdminPalette.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            playlist?.name ?? '…',
                            style: const TextStyle(
                              color: AdminPalette.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (playlist != null)
                          IconButton(
                            onPressed: () => _renamePlaylist(playlist),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: AdminPalette.textDim,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: entries.when(
                      loading: () => const SizedBox(),
                      error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Failed to load videos.\n$e'),
                      data: (items) => items.isEmpty
                          ? const EmptyState(
                              icon: Icons.movie_outlined,
                              message: 'No videos in this playlist yet.\nUpload one below.',
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                              itemCount: items.length,
                              onReorder: (oldIndex, newIndex) => _reorder(items, oldIndex, newIndex),
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return _VideoRow(
                                  key: ValueKey(item.entryId),
                                  index: i,
                                  item: item,
                                  durationLabel: _formatDuration(item.durationSeconds),
                                  onRename: () => _renameVideo(item),
                                  onMove: () => _moveVideo(item),
                                  onRemove: () => _removeVideo(item),
                                );
                              },
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    child: Row(
                      children: [
                        if (_isUploading) ...[
                          LiquidUploadRing(progress: _progress, size: 44),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Uploading…',
                              style: TextStyle(color: AdminPalette.textDim, fontSize: 13),
                            ),
                          ),
                        ] else ...[
                          if (_message != null)
                            Expanded(
                              child: Text(
                                _message!,
                                style: const TextStyle(color: AdminPalette.textDim, fontSize: 13),
                              ),
                            )
                          else
                            const Spacer(),
                          AdminPillButton(
                            label: 'Upload Video',
                            icon: Icons.upload_outlined,
                            onPressed: _pickAndUpload,
                          ),
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
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    super.key,
    required this.index,
    required this.item,
    required this.durationLabel,
    required this.onRename,
    required this.onMove,
    required this.onRemove,
  });

  final int index;
  final PlaylistVideoItem item;
  final String durationLabel;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            MonoLabel(index.toString().padLeft(2, '0'), color: AdminPalette.textDim.withValues(alpha: 0.5), fontSize: 14),
            const SizedBox(width: 16),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AdminPalette.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.movie_outlined, size: 20, color: AdminPalette.textPrimary.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            MonoLabel(durationLabel),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AdminPalette.textDim),
              color: AdminPalette.surfaceRaised,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'move') onMove();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: AdminPalette.textPrimary))),
                PopupMenuItem(value: 'move', child: Text('Move to playlist…', style: TextStyle(color: AdminPalette.textPrimary))),
                PopupMenuItem(value: 'remove', child: Text('Remove from playlist', style: TextStyle(color: AdminPalette.danger))),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.drag_indicator, color: AdminPalette.textDim.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
