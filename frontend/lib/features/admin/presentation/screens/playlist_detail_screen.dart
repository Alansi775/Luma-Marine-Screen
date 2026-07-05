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
  }

  Future<void> _moveVideo(PlaylistVideoItem item) async {
    final playlists = ref.read(adminPlaylistsProvider).value ?? const <AdminPlaylist>[];
    final candidates = playlists.where((p) => p.id != widget.playlistId).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No alternate arrays available for transfer.'),
        backgroundColor: AdminPalette.surfaceRaised,
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Text(
                    'TRANSFER TO',
                    style: TextStyle(color: AdminPalette.textDim, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ),
                for (final p in candidates)
                  InkWell(
                    onTap: () => Navigator.pop(context, p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Text(p.name, style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 16)),
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
          borderRadius: 32,
          elevated: true,
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AdminPalette.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminPalette.hairlineBright),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    cursorColor: AdminPalette.accent,
                    style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    ),
                    onSubmitted: (value) => Navigator.pop(context, value),
                  ),
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
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 40, 32),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AdminPalette.textDim,
                          splashRadius: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            playlist?.name ?? 'Loading Sequence...',
                            style: const TextStyle(
                              color: AdminPalette.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (playlist != null)
                          Container(
                            decoration: BoxDecoration(
                              color: AdminPalette.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _renamePlaylist(playlist),
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              color: AdminPalette.textPrimary,
                              tooltip: 'Edit Sequence',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- List Area ---
                  Expanded(
                    child: entries.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AdminPalette.accent)),
                      error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Data failure.\n$e'),
                      data: (items) => items.isEmpty
                          ? const EmptyState(
                              icon: Icons.movie_filter_outlined,
                              message: 'Sequence is empty.\nInject media below.',
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                              itemCount: items.length,
                              proxyDecorator: (child, index, animation) => Material(
                                color: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)]),
                                  child: child,
                                ),
                              ),
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

                  // --- Upload Action Bar ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                    child: Row(
                      children: [
                        if (_isUploading) ...[
                          LiquidUploadRing(progress: _progress, size: 56), // الدائرة الكبيرة للتحميل
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('TRANSMITTING', style: TextStyle(color: AdminPalette.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                                SizedBox(height: 4),
                                Text('Synchronizing node data...', style: TextStyle(color: AdminPalette.textDim, fontSize: 14)),
                              ],
                            ),
                          ),
                        ] else ...[
                          if (_message != null)
                            Expanded(
                              child: Text(
                                _message!,
                                style: const TextStyle(color: AdminPalette.textDim, fontSize: 14),
                              ),
                            )
                          else
                            const Spacer(),
                          AdminPillButton(
                            label: 'Inject Media',
                            icon: Icons.upload_rounded,
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
          // التوهج السينمائي العظيم وقت الرفع فقط
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
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassPanel(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            MonoLabel((index + 1).toString().padLeft(2, '0'), color: AdminPalette.textDim.withValues(alpha: 0.5), fontSize: 15),
            const SizedBox(width: 20),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AdminPalette.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminPalette.hairline),
              ),
              child: Icon(Icons.smart_display_rounded, size: 22, color: AdminPalette.textPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            MonoLabel(durationLabel, fontSize: 14),
            const SizedBox(width: 16),
            GlassMenuButton(
              items: [
                GlassMenuItem(label: 'Rename', onTap: onRename),
                GlassMenuItem(label: 'Transfer…', onTap: onMove),
                GlassMenuItem(label: 'Extract', danger: true, onTap: onRemove),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.drag_indicator_rounded, color: AdminPalette.textDim.withValues(alpha: 0.3), size: 24),
          ],
        ),
      ),
    );
  }
}