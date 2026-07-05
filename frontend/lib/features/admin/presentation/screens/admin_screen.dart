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
import '../theme/admin_design_kit.dart';

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
      builder: (context) => _AdminDialog(
        title: 'Delete Playlist',
        body: 'Delete "${playlist.name}" and remove all its videos from it? '
            'The videos themselves stay in the catalog.',
        actions: [
          _DialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
          _DialogAction(label: 'Delete', danger: true, onPressed: () => Navigator.pop(context, true)),
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
      builder: (context) => _AdminDialog(
        title: title,
        field: controller,
        actions: [
          _DialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          _DialogAction(label: 'Save', onPressed: () => Navigator.pop(context, controller.text)),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(adminPlaylistsProvider);
    final activePlaylistId = ref.watch(activePlaylistIdProvider).value;
    final email = ref.watch(authRepositoryProvider).currentUserEmail;

    return Scaffold(
      backgroundColor: AdminPalette.black,
      body: SafeArea(
        child: AdminPageWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Row(
                  children: [
                    const BrandLogo(size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAYLISTS',
                          style: TextStyle(
                            color: AdminPalette.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        if (email != null) ...[
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(color: AdminPalette.textDim, fontSize: 12)),
                        ],
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _signOut(context, ref),
                      icon: const Icon(Icons.logout, size: 20),
                      color: AdminPalette.textDim,
                      tooltip: 'Sign out',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: playlists.when(
                  loading: () => const SizedBox(),
                  error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Failed to load playlists.\n$e'),
                  data: (items) => items.isEmpty
                      ? const EmptyState(
                          icon: Icons.playlist_add,
                          message: 'No playlists yet.\nCreate one to start uploading videos.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 108,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final playlist = items[i];
                            final isActive = playlist.id == activePlaylistId;
                            return _PlaylistCard(
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
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AdminPillButton(
                    label: 'New Playlist',
                    icon: Icons.add,
                    filled: false,
                    onPressed: () => _createPlaylist(context, ref),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
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
    const radius = 24.0;
    final card = GlassPanel(
      borderRadius: radius,
      borderColor: isActive ? Colors.transparent : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdminPalette.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.queue_music, color: AdminPalette.textPrimary.withValues(alpha: 0.8)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        color: AdminPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AdminPalette.accent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ON AIR',
                            style: TextStyle(
                              color: AdminPalette.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AdminPillButton(
                label: isActive ? 'Stop' : 'Set Live',
                filled: !isActive,
                onPressed: onToggleActive,
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AdminPalette.textDim),
                color: AdminPalette.surfaceRaised,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: AdminPalette.textPrimary))),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AdminPalette.danger))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return isActive ? OnAirGlow(borderRadius: radius, child: card) : card;
  }
}

class _AdminDialog extends StatelessWidget {
  const _AdminDialog({required this.title, this.body, this.field, required this.actions});

  final String title;
  final String? body;
  final TextEditingController? field;
  final List<_DialogAction> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              Text(
                title,
                style: const TextStyle(color: AdminPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (body != null)
                Text(body!, style: const TextStyle(color: AdminPalette.textDim, height: 1.5)),
              if (field != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AdminPalette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AdminPalette.hairline),
                  ),
                  child: TextField(
                    controller: field,
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
                children: [for (final action in actions) ...[action, const SizedBox(width: 12)]],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({required this.label, required this.onPressed, this.danger = false});

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: danger ? AdminPalette.danger : AdminPalette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
