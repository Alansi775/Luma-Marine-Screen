import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/admin_playlist.dart';
import '../providers/admin_providers.dart';

/// Playlist hub — the admin's landing screen. Lists every playlist, shows
/// which one is currently on air, and is where playlists themselves are
/// created/renamed/deleted. Uploading videos happens one level down, on
/// [PlaylistDetailScreen] — there is no upload entry point here, which is
/// what makes "you must create a playlist before you can upload anything"
/// true by construction rather than a validation message.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRoutes.nowPlaying);
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await _promptForName(context, title: 'New Playlist', initialValue: '');
    if (name == null || name.trim().isEmpty) return;
    try {
      final id = await ref.read(playlistManagementRepositoryProvider).createPlaylist(name.trim());
      if (context.mounted) context.push(AppRoutes.adminPlaylist(id));
    } on NetworkException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _renamePlaylist(BuildContext context, WidgetRef ref, AdminPlaylist playlist) async {
    final name = await _promptForName(context, title: 'Rename Playlist', initialValue: playlist.name);
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(playlistManagementRepositoryProvider).renamePlaylist(playlist.id, name.trim());
    } on NetworkException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _deletePlaylist(BuildContext context, WidgetRef ref, AdminPlaylist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}" and remove all its videos from it? '
            'The videos themselves stay in the catalog.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(playlistManagementRepositoryProvider).deletePlaylist(playlist.id);
    } on NetworkException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _setActive(WidgetRef ref, AdminPlaylist playlist, bool isCurrentlyActive) async {
    await ref
        .read(playlistManagementRepositoryProvider)
        .setActivePlaylist(isCurrentlyActive ? null : playlist.id);
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlists = ref.watch(adminPlaylistsProvider);
    final activePlaylistId = ref.watch(activePlaylistIdProvider).value;
    final email = ref.watch(authRepositoryProvider).currentUserEmail;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const BrandLogo(size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PLAYLISTS', style: theme.textTheme.labelSmall),
                      if (email != null) Text(email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _signOut(context, ref),
                    child: const Text('SIGN OUT'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: playlists.when(
                loading: () => const SizedBox(),
                error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Failed to load playlists.\n$e'),
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        icon: Icons.playlist_add,
                        message: 'No playlists yet.\nCreate one to start uploading videos.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final playlist = items[i];
                          final isActive = playlist.id == activePlaylistId;
                          return _PlaylistRow(
                            playlist: playlist,
                            isActive: isActive,
                            onTap: () => context.push(AppRoutes.adminPlaylist(playlist.id)),
                            onRename: () => _renamePlaylist(context, ref, playlist),
                            onDelete: () => _deletePlaylist(context, ref, playlist),
                            onToggleActive: () => _setActive(ref, playlist, isActive),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _createPlaylist(context, ref),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('NEW PLAYLIST'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.playlist,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onToggleActive,
  });

  final AdminPlaylist playlist;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.queue_music, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name, style: theme.textTheme.bodyLarge),
                  if (isActive) ...[
                    const SizedBox(height: 2),
                    Text('ON AIR', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface)),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onToggleActive,
              child: Text(isActive ? 'STOP' : 'SET LIVE'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
