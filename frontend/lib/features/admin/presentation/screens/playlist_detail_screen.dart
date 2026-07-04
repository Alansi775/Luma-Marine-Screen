import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/admin_playlist.dart';
import '../../domain/entities/playlist_video_item.dart';
import '../providers/admin_providers.dart';

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
      builder: (context) => SimpleDialog(
        title: const Text('Move to playlist'),
        children: candidates
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Text(p.name),
                ))
            .toList(),
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('SAVE')),
        ],
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '—';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlists = ref.watch(adminPlaylistsProvider).value ?? const <AdminPlaylist>[];
    final playlist = playlists.where((p) => p.id == widget.playlistId).firstOrNull;
    final entries = ref.watch(playlistEntriesProvider(widget.playlistId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(
                      playlist?.name ?? '…',
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (playlist != null)
                    IconButton(
                      onPressed: () => _renamePlaylist(playlist),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) => _reorder(items, oldIndex, newIndex),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return _VideoRow(
                            key: ValueKey(item.entryId),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isUploading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 3,
                        backgroundColor: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_message != null) ...[
                    Text(_message!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: const Icon(Icons.upload_outlined, size: 20),
                    label: const Text('UPLOAD VIDEO TO THIS PLAYLIST'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    super.key,
    required this.item,
    required this.durationLabel,
    required this.onRename,
    required this.onMove,
    required this.onRemove,
  });

  final PlaylistVideoItem item;
  final String durationLabel;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.movie_outlined, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.name, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
          ),
          Text(durationLabel, style: theme.textTheme.bodyMedium),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'rename') onRename();
              if (value == 'move') onMove();
              if (value == 'remove') onRemove();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'move', child: Text('Move to playlist…')),
              PopupMenuItem(value: 'remove', child: Text('Remove from playlist')),
            ],
          ),
        ],
      ),
    );
  }
}
