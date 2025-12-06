import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/core/providers/retry_connection_provider.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';

import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

class NoInternetView extends ConsumerStatefulWidget {
  const NoInternetView({super.key});

  @override
  ConsumerState<NoInternetView> createState() => _NoInternetViewState();
}

class _NoInternetViewState extends ConsumerState<NoInternetView> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    try {
      final retryFunction = ref.read(retryConnectionProvider);
      final destinationRoute = await retryFunction();

      if (mounted) {
        context.go(destinationRoute);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          'Sin conexión',
          'No se pudo conectar. Revisa tu conexión e intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color dynamicColor = colors.primary;

    try {
      final authState = ref.watch(authStateProvider).valueOrNull;
      final currentAuthUserId = authState?.session?.user.id;

      if (currentAuthUserId != null) {
        final profileState = ref.watch(
          userProfileByIdProvider(currentAuthUserId),
        );
        final profile = profileState.asData?.value;

        final avatarsState = ref.watch(currentUserAvatarsProvider);
        final avatarsList = avatarsState.asData?.value ?? [];

        if (profile != null) {
          dynamicColor = avatarsList.isNotEmpty
              ? getAvatarColorById(profile.idAvatarSeleccionado, avatarsList)
              : AllStatsView.getHeaderColor(profile, colors);
        }
      }
      // ignore: empty_catches
    } catch (e) {}

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dynamicColor.withAlpha(100),
                  colors.surfaceContainerLowest,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/home/alerta.webp',
                      width: 200,
                      cacheWidth: 400,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '¡Oops! Sin conexión',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Parece que no puedes conectarte. Revisa tu conexión a Internet y vuelve a intentarlo.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    _isRetrying
                        ? CircularProgressIndicator(color: dynamicColor)
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dynamicColor,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              textStyle: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _handleRetry,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
