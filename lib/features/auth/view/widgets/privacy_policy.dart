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
    // 1. Escuchamos el provider
    final policyAsync = ref.watch(privacyPolicyProvider);

    // 2. Definimos estilos basados en tu authTheme (Colores blancos sobre fondo oscuro)
    final headingStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white, // Títulos en blanco puro
      fontFamily: 'Poppins',
    );

    final bodyStyle = const TextStyle(
      fontSize: 14,
      color: Colors.white70, // Texto normal un poco más suave
      height: 1.5,
      fontFamily: 'Poppins',
    );

    // 3. Aplicamos el authTheme para mantener la coherencia visual
    return Theme(
      data: authTheme,
      child: Scaffold(
        body: AuthBackground(
          isScrollable: false, // Importante: AuthBackground fijo
          showFox: false, // Sin zorro, queremos leer texto
          child: Column(
            children: [
              // --- Cabecera con botón Atrás ---
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
                    const SizedBox(
                      width: 48,
                    ), // Para balancear el icono de atrás
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- Contenido Dinámico ---
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ), // Para que no se estire demasiado en tablets
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  // Aquí decidimos qué mostrar según el estado de la carga
                  child: policyAsync.when(
                    // A) Cargando
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEE7D05),
                      ),
                    ),

                    // B) Error
                    error: (err, stack) => Center(
                      child: Text(
                        'No se pudo cargar la política.\nVerifica tu conexión.',
                        textAlign: TextAlign.center,
                        style: bodyStyle,
                      ),
                    ),

                    // C) Datos listos (Aquí renderizamos el JSON)
                    data: (contentList) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40, top: 10),
                        itemCount: contentList.length,
                        itemBuilder: (context, index) {
                          final item = contentList[index];
                          final tipo = item['tipo']; // 'h' o 'p'
                          final texto = item['texto'];

                          if (tipo == 'h') {
                            // Renderizar Título
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                bottom: 8,
                              ),
                              child: Text(texto, style: headingStyle),
                            );
                          } else {
                            // Renderizar Párrafo
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(texto, style: bodyStyle),
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
