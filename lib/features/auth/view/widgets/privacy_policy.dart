import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/auth/view/auth_view.dart';

class PrivacyPolicyView extends ConsumerWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(privacyPolicyProvider);

    final headingStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Poppins',
    );

    final bodyStyle = const TextStyle(
      fontSize: 14,
      color: Colors.white70,
      height: 1.5,
      fontFamily: 'Poppins',
    );

    return Theme(
      data: authTheme,
      child: Scaffold(
        body: AuthBackground(
          isScrollable: false,
          showFox: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Política de Privacidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: policyAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEE7D05),
                      ),
                    ),

                    error: (err, stack) => Center(
                      child: Text(
                        'No se pudo cargar la política.\nVerifica tu conexión.',
                        textAlign: TextAlign.center,
                        style: bodyStyle,
                      ),
                    ),

                    data: (contentList) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40, top: 10),
                        itemCount: contentList.length,
                        itemBuilder: (context, index) {
                          final item = contentList[index];
                          final tipo = item['tipo'];
                          final texto = item['texto'];

                          if (tipo == 'h') {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                bottom: 8,
                              ),
                              child: Text(
                                texto,
                                style: headingStyle,
                                textAlign: TextAlign.left,
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                texto,
                                style: bodyStyle,
                                textAlign: TextAlign.justify,
                              ),
                            );
                          }
                        },
                      );
                    },
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
