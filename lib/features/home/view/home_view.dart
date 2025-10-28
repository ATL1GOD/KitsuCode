import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/features/home/view/widgets/map_home.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int iCurrentSection = 0;
  final heightFirstBox = 56.0;
  // SUGERENCIA: 600.0 es más realista que 816.0 para forzar el scroll
  final heightSection = 600.0;
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(scrollListener);
  }

  void scrollListener() {
    final sectionsAsync = ref.read(homeViewModelProvider);

    sectionsAsync.whenData((sections) {
      if (sections.isEmpty) return; // Evita división por cero si no hay datos

      final currentScroll = scrollCtrl.position.pixels - heightFirstBox - 24.0;
      int index = (currentScroll / heightSection).floor();

      index = index.clamp(0, sections.length - 1); // Limita el índice

      if (index != iCurrentSection) {
        setState(() => iCurrentSection = index);
      }
    });
  }

  @override
  void dispose() {
    scrollCtrl.removeListener(scrollListener);
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: sectionsAsync.when(
        data: (sections) {
          if (sections.isEmpty) {
            return const Center(child: Text("No hay secciones disponibles."));
          }

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/home/camino.png'),
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              ),
              // El ListView es lo que maneja el scroll
              ListView.separated(
                controller: scrollCtrl,
                itemBuilder: (_, i) => i == 0
                    ? SizedBox(height: heightFirstBox)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Section(data: sections[i - 1]),
                          // Esto es opcional, pero ayuda a generar altura
                          const SizedBox(height: 100.0),
                        ],
                      ),
                separatorBuilder: (_, i) => const SizedBox(height: 24.0),
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
                itemCount: sections.length + 1,
              ),
              Positioned(
                top: 40.0,
                left: 0,
                right: 0,
                child: CurrentSection(
                  data: sections[iCurrentSection.clamp(0, sections.length - 1)],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error al cargar: $err")),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

// Widget restaurado para mostrar la sección actual en la parte superior.
class CurrentSection extends StatelessWidget {
  final SectionData data;

  const CurrentSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(16.0),
        border: Border(bottom: BorderSide(color: data.colorOscuro, width: 4.0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // CORRECCIÓN CLAVE: Se elimina 'SECCIÓN ${data.seccion}'
                  // Se deja solo 'ETAPA ${data.etapa}'
                  'ETAPA ${data.etapa}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  data.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: data.colorOscuro, width: 2.0),
              ),
            ),
            // Puedes añadir un icono aquí
          ),
        ],
      ),
    );
  }
}
