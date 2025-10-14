// lib/features/competences/view/widgets/ranking_error_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

class RankingErrorWidget extends ConsumerWidget {
  final Object error;

  const RankingErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    
    // Identificar el tipo de error para TA_2 o TA_3
    // E_05: Error de Servidor | E_06: Error de Conexión (implícito si no es E_05)
    final isServerError = error.toString().contains('E_05'); 
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isServerError ? Icons.storage_outlined : Icons.cloud_off, size: 60, color: colors.error), //
            const SizedBox(height: 16),
            Text(
              isServerError 
                  ? 'E_05: Problema con el servidor. [TA_3]'
                  : 'E_06: Problema de conexión a Internet. [TA_2]',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurface),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isServerError) // Solo si es error de conexión (E_06/TA_2)
                  TextButton(
                    onPressed: () => ref.refresh(globalRankingProvider), // Reintentar
                    child: const Text('Reintentar'), // Paso 4 de TA_2
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => context.pop(), // Salir (Paso 7 de TA_2 o Paso 4 de TA_3)
                  style: ElevatedButton.styleFrom(backgroundColor: colors.error), //
                  child: const Text('Salir'), 
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}