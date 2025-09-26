import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:shimmer/shimmer.dart';

// Función para obtener la ruta del icono basado en el nombre del logro
String _getAchievementIconPath(String achievementName) {
  switch (achievementName.toLowerCase()) {
    case 'primer reto':
      return 'assets/images/logro_1.png'; 
    case 'racha de 5 días':
      return 'assets/images/logro_racha.png'; 
    case 'experto en java':
      return 'assets/images/logro_java.png'; 
    
    default:
      return 'assets/images/logro_default.png'; // Icono por defecto
  }
}

class ProfileAchievementsSection extends ConsumerWidget {
  const ProfileAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(userAchievementsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El título y el botón "Ver todo" ahora están en su propio `when`
          //    para decidir si el botón debe mostrarse.
          achievementsState.when(
            // Mientras carga o si hay error, solo mostramos el título
            loading: () => Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
            error: (e, s) => Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
            // Cuando hay datos...
            data: (achievements) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Logros',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  // Si la lista NO está vacía, muestra el botón
                  if (achievements.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        // TODO: Navegar a la pantalla de "Todos los logros"
                      },
                      child: Text(
                        'Ver todo',
                        style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // 2. Un segundo `when` se encarga de mostrar la lista o el mensaje
          achievementsState.when(
            loading: () => const _AchievementsLoadingShimmer(),
            error: (error, stack) => const Center(child: Text('No se pudieron cargar los logros')),
            data: (achievements) {
              // Si la lista está vacía, muestra el mensaje que habíamos quitado
              if (achievements.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('¡Aún no has conseguido logros!'),
                  ),
                );
              }
              // Si no, muestra la lista de logros
              return SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final imagePath = _getAchievementIconPath(achievement.nombre);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Tooltip(
                        message: '${achievement.nombre}\n${achievement.descripcion}',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: colors.primaryContainer.withOpacity(0.7),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              imagePath,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error_outline, color: colors.error);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// WIDGET DE SHIMMER PARA EL ESTADO DE CARGA 
class _AchievementsLoadingShimmer extends StatelessWidget {
  const _AchievementsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4, // Muestra 4 placeholders
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: CircleAvatar(radius: 40, backgroundColor: Colors.white),
          ),
        ),
      ),
    );
  }
}