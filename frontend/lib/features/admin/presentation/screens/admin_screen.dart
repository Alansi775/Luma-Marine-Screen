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
          AdminPillButton(label: 'Cancel', filled: false, onPressed: () => Navigator.pop(context, false)),
          AdminPillButton(label: 'Delete', danger: true, onPressed: () => Navigator.pop(context, true)),
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
          AdminPillButton(label: 'Cancel', filled: false, onPressed: () => Navigator.pop(context)),
          AdminPillButton(label: 'Save', onPressed: () => Navigator.pop(context, controller.text)),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    final c = AdminColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: c.textPrimary)),
      backgroundColor: c.surfaceRaised,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AdminColors.of(context);
    final playlists = ref.watch(adminPlaylistsProvider);
    final activePlaylistId = ref.watch(activePlaylistIdProvider).value;
    final email = ref.watch(authRepositoryProvider).currentUserEmail;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: AdminPageWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Premium Header ---
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 48, 40, 32),
                child: Row(
                  children: [
                    const BrandLogo(size: 44),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTROL CENTER',
                          style: TextStyle(color: c.textDim, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email ?? 'Luma Node',
                          style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: c.hairline), shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: () => _signOut(context, ref),
                        icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                        color: c.textDim,
                        tooltip: 'Sign out',
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Master Module (On-Air) + secondary grid ---
              // "Master Module Strategy": the live playlist gets a full-width
              // hero module, not just a highlighted cell among equals — a
              // grid of identical cards reads as generic Android/Material,
              // regardless of theming. Everything else demotes to a dense
              // technical grid underneath.
              Expanded(
                child: playlists.when(
                  loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
                  error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'System fault.\n$e'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.layers_clear_outlined,
                        message: 'No sequences detected.\nInitialize a new playlist to broadcast.',
                      );
                    }
                    final active = items.where((p) => p.id == activePlaylistId).firstOrNull;
                    final others = items.where((p) => p.id != activePlaylistId).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (active != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                            child: _MasterOnAirModule(
                              playlist: active,
                              onTap: () => context.push(AppRoutes.adminPlaylist(active.id)),
                              onRename: () => _renamePlaylist(context, ref, active),
                              onDelete: () => _deletePlaylist(context, ref, active),
                              onToggleActive: () => _setActive(ref, active, true),
                            ),
                          ),
                        Expanded(
                          child: others.isEmpty
                              ? const SizedBox()
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 400,
                                    mainAxisExtent: 120,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                  ),
                                  itemCount: others.length,
                                  itemBuilder: (context, i) {
                                    final playlist = others[i];
                                    return _PlaylistCard(
                                      playlist: playlist,
                                      isActive: false,
                                      onTap: () => context.push(AppRoutes.adminPlaylist(playlist.id)),
                                      onRename: () => _renamePlaylist(context, ref, playlist),
                                      onDelete: () => _deletePlaylist(context, ref, playlist),
                                      onToggleActive: () => _setActive(ref, playlist, false),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // --- Footer Action ---
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                child: AdminPillButton(
                  label: 'Initialize Playlist',
                  icon: Icons.add_rounded,
                  filled: false,
                  onPressed: () => _createPlaylist(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Master Module": the on-air playlist gets a full-width hero, not
/// just a highlighted cell among equals — see the build-method comment
/// on why that distinction is the point.
class _MasterOnAirModule extends StatelessWidget {
  const _MasterOnAirModule({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onToggleActive,
  });

  final AdminPlaylist playlist;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    return OnAirGlow(
      borderRadius: 32,
      child: GlassPanel(
        borderRadius: 32,
        elevated: true,
        padding: const EdgeInsets.fromLTRB(36, 32, 28, 32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    LiveEqualizer(color: c.accent, size: 18),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        playlist.name,
                        style: TextStyle(color: c.textPrimary, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              AdminPillButton(label: 'Halt Station', danger: true, onPressed: onToggleActive),
              const SizedBox(width: 8),
              GlassMenuButton(
                items: [
                  GlassMenuItem(label: 'Rename Sequence', icon: Icons.edit_outlined, onTap: onRename),
                  GlassMenuItem(label: 'Terminate Sequence', icon: Icons.delete_outline, danger: true, onTap: onDelete),
                ],
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
    final c = AdminColors.of(context);
    const radius = 28.0;

    return GlassPanel(
      borderRadius: radius,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.layers_rounded, color: c.textPrimary.withValues(alpha: 0.8), size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  playlist.name,
                  style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AdminPillButton(label: 'Deploy', onPressed: onToggleActive),
              const SizedBox(width: 8),
              GlassMenuButton(
                items: [
                  GlassMenuItem(label: 'Rename Sequence', icon: Icons.edit_outlined, onTap: onRename),
                  GlassMenuItem(label: 'Terminate Sequence', icon: Icons.delete_outline, danger: true, onTap: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDialog extends StatelessWidget {
  const _AdminDialog({required this.title, this.body, this.field, required this.actions});

  final String title;
  final String? body;
  final TextEditingController? field;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
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
              Text(title, style: TextStyle(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              if (body != null) Text(body!, style: TextStyle(color: c.textDim, fontSize: 15, height: 1.6)),
              if (field != null)
                AdminTextField(
                  controller: field!,
                  autofocus: true,
                  onSubmitted: (value) => Navigator.pop(context, value),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions.expand((action) => [action, const SizedBox(width: 12)]).toList()..removeLast(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
