import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _isUploading = false;
  double _progress = 0;
  String? _message;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
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
            onProgress: (p) => setState(() => _progress = p),
          );
      setState(() => _message = 'Uploaded "${file.name}" — it will sync to the screen shortly.');
    } on NetworkException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go(AppRoutes.nowPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authRepositoryProvider).currentUserEmail;

    return AppScaffold(
      title: 'Admin',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (email != null)
                  Text('Signed in as $email', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isUploading ? null : _pickAndUpload,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Pick & Upload Video'),
                ),
                if (_isUploading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 32),
                OutlinedButton(onPressed: _signOut, child: const Text('Sign Out')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
