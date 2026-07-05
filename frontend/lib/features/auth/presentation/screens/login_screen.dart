import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../features/admin/presentation/theme/admin_design_kit.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../providers/auth_providers.dart';

/// Reached only via the hidden long-press gesture on the idle/splash
/// screen (see shared/widgets/bootstrap_screen.dart) — there's no visible
/// link to this from normal signage playback. Follows the system's
/// light/dark preference (see `AdminColors`'s doc comment) — this should
/// read as stepping into a control room, not a settings page.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go(AppRoutes.admin);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      // Belt-and-suspenders: AuthException covers every case
      // FirebaseAuthRepository is documented to throw, but a silent
      // "nothing happened" on an unexpected error type is worse than an
      // unpolished message.
      setState(() => _errorMessage = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned.fill(child: _AmbientGlow(color: c.accent, background: c.background)),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => context.go(AppRoutes.nowPlaying),
                    icon: const Icon(Icons.arrow_back),
                    color: c.textDim,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: GlassPanel(
                        borderRadius: 32,
                        elevated: true,
                        padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: BrandLogo(size: 84)),
                            const SizedBox(height: 36),
                            Text(
                              'ADMIN ACCESS',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.textDim, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3),
                            ),
                            const SizedBox(height: 36),
                            AdminTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 14),
                            AdminTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: c.danger, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.center,
                              child: _isSubmitting
                                  ? SizedBox(
                                      height: 52,
                                      width: 52,
                                      child: Center(
                                        child: SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                                        ),
                                      ),
                                    )
                                  : AdminPillButton(label: 'Sign In', onPressed: _submit),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, required this.background});

  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [color.withValues(alpha: 0.10), background],
        ),
      ),
    );
  }
}
