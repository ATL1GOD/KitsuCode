// features/desafio/presentation/views/desafio_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
// Importa el widget de la tarjeta que ahora está en su propio archivo
import 'package:kitsucode/features/desafio/view/widgets/expandable_special_event_card.dart';

class DesafiosView extends ConsumerWidget {
  const DesafiosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);

    return Scaffold(
      body: desafiosAsync.when(
        data: (data) {
          // --- Sección del Reto Agrupador (Mensual) ---
          if (data.agrupador != null) {
            return ListView(
              children: [
                // El widget principal ahora está importado
                ExpandableSpecialEventCard(
                  evento: data.agrupador!, // El Reto Agrupador
                  desafiosMensuales:
                      data.individuales, // Los retos individuales del mes
                  completedRetoIds:
                      data.completedRetoIds, // IDs completados para el progreso
                  isParentCompleted: data.isParentCompleted,
                ),
              ],
            );
          }

          // Mensaje si no hay un reto mensual activo
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                '🎉 No hay un evento especial mensual activo en este momento. ¡Vuelve pronto!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
