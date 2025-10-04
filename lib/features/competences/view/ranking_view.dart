// lib/features/competences/view/ranking_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart'; 
import 'package:kitsucode/features/competences/provider/ranking_provider.dart';
import 'package:animate_do/animate_do.dart';
// <-- Importamos los widgets modulares
import 'package:kitsucode/features/competences/view/widgets/ranking_error_widget.dart';
import 'package:kitsucode/features/competences/view/widgets/ranking_filters_widget.dart';
import 'package:kitsucode/features/competences/view/widgets/ranking_tile.dart';


class RankingView extends ConsumerWidget {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el estado de autenticación para la restricción (TA_1 / MSJ_11)
    final authState = ref.watch(authStateProvider);
    final isLogged = authState.value?.session != null;
    
    if (!isLogged) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clasificación')),
        body: _buildNotAuthenticatedScreen(context),
      );
    }
    
    return const Scaffold(
      body: _RankingContent(),
    );
  }
  
  // Widget para la Trayectoria Alternativa TA_1 (No autenticado)
  Widget _buildNotAuthenticatedScreen(BuildContext context) {
      final colors = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: colors.secondary), 
              const SizedBox(height: 20),
              Text(
                'MSJ_11: Sección inaccesible. Para acceder, primero debes iniciar sesión',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Ingresar'), 
              ),
            ],
          ),
        ),
      );
  }
}

class _RankingContent extends ConsumerWidget {
  const _RankingContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final rankingAsync = ref.watch(globalRankingProvider);
    final authUser = ref.read(authStateProvider).value?.session?.user; 
    
    final currentUsername = authUser?.userMetadata?['user_name'] ?? 'dxniel7'; 

    return Scaffold(
      // 1. APPBAR ESTÁNDAR (Fijo: Contiene solo el título)
      appBar: AppBar(
        title: const Text('Tabla de Clasificación'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0, 
      ),
      body: Stack(
        children: [
          
          // --- ZORRO ANIMADO Y PERMANENTE (Fijo) ---
          Positioned(
            top: 0,
            right: -50, 
            child: Pulse(
              animate: true,
              infinite: true,
              delay: const Duration(seconds: 1),
              duration: const Duration(seconds: 5),
              child: Opacity( 
                opacity: 0.5, 
                child: Image.asset(
                  'assets/images/login_zorro.png', 
                  width: 140, 
                  height: 140,
                ),
              ),
            ),
          ),
          
          // --- CONTENIDO PRINCIPAL (Filtros Fijos + Lista Scrollable) ---
          Column( 
            children: [
              
              // 2. FILTROS FIJOS (Modularizado)
              const RankingFiltersWidget(), // 💡 ESTE WIDGET ES ESTATICO

              // 3. LISTA SCROLLABLE (Expandida para llenar el espacio restante)
              Expanded( // Permite que la lista tome el espacio restante para hacer scroll
                child: rankingAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: RankingErrorWidget(error: e)),
                  data: (ranking) {
                    if (ranking.isEmpty) {
                      return const Center(child: Text('No hay usuarios en este ranking aún.'));
                    }
                    
                    // Usamos ListView.builder para el scroll de la tabla
                    return ListView.builder(
                      // IMPORTANTE: quitamos el padding para que el scroll comience justo después de los filtros
                      padding: EdgeInsets.zero, 
                      itemCount: ranking.length,
                      itemBuilder: (context, index) {
                          final user = ranking[index];
                          final isCurrentUser = user.username == currentUsername;
                          
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            child: RankingTile(
                              user: user,
                              isTop3: index < 3,
                              isCurrentUser: isCurrentUser,
                              colors: colors,
                            ),
                          );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}