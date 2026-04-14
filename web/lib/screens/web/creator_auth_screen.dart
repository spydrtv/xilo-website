import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/creator_upload_service.dart';
import '../../theme/theme.dart';
import '../../widgets/common/xilo_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Creator Auth Screen — magic link sign-in / sign-up
// ─────────────────────────────────────────────────────────────────────────────

class CreatorAuthScreen extends StatefulWidget {
  const CreatorAuthScreen({super.key});

  @override
  State<CreatorAuthScreen> createState() => _CreatorAuthScreenState();
}

class _CreatorAuthScreenState extends State<CreatorAuthScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _linkSent = false;
  String? _errorMessage;

  late final CreatorUploadService _authService;

  @override
  void initState() {
    super.initState();
    _authService = CreatorUploadService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendMagicLink(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _linkSent = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not send link. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      body: Column(
        children: [
          // ── Nav Bar (minimal) ─────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXl),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                XiloLogo(onTap: () => context.go('/web')),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/web/creator'),
                  child: const Text('Back to Creator Hub'),
                ),
              ],
            ),
          ),
          // ── Auth card ─────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient icon
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            colors.gradient1,
                            colors.gradient2,
                          ],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.mic_external_on_rounded,
                          size: AppTheme.iconXl,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        _linkSent
                            ? 'Check your inbox'
                            : 'Creator sign-in',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        _linkSent
                            ? 'We sent a magic link to ${_emailController.text.trim()}. Click it to access your Creator Dashboard — no password needed.'
                            : 'Enter your email and we\'ll send you a magic link. No password required.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.subtleText),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      if (!_linkSent) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Email address',
                                  style:
                                      theme.textTheme.titleSmall),
                              const SizedBox(
                                  height: AppTheme.spacingXs),
                              TextFormField(
                                controller: _emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText:
                                      'your@email.com',
                                  prefixIcon: Icon(
                                      Icons.email_outlined),
                                ),
                                validator: (val) {
                                  if (val == null ||
                                      val.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(val.trim())) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) =>
                                    _sendMagicLink(),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(
                                    height: AppTheme.spacingSm),
                                Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: colors.danger),
                                ),
                              ],
                              const SizedBox(
                                  height: AppTheme.spacingLg),
                              ElevatedButton.icon(
                                onPressed:
                                    _loading ? null : _sendMagicLink,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded),
                                label: Text(_loading
                                    ? 'Sending…'
                                    : 'Send magic link'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(
                                      double.infinity,
                                      AppTheme.buttonHeight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Success state
                        Container(
                          padding: const EdgeInsets.all(
                              AppTheme.spacingLg),
                          decoration: BoxDecoration(
                            color: colors.success
                                .withOpacity(AppTheme.opacitySubtle),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium),
                            border: Border.all(
                                color: colors.success
                                    .withOpacity(AppTheme.opacityHint)),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: colors.success,
                                  size: AppTheme.iconMd),
                              const SizedBox(
                                  width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  'Magic link sent! Check your email and click the link to sign in.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        TextButton(
                          onPressed: () => setState(() {
                            _linkSent = false;
                            _emailController.clear();
                          }),
                          child:
                              const Text('Use a different email'),
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingXl),
                      Divider(
                          color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'New to XILO? Entering your email above will create a free creator account automatically.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.subtleText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
