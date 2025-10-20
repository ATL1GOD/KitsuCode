import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/features/home/view/widgets/map_home.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  // 2. Cambia 'State' por 'ConsumerState'
  ConsumerState<HomeView> createState() => _HomeViewState();
}

// 3. Cambia '_HomeViewState' para que extienda 'ConsumerState<HomeView>'
class _HomeViewState extends ConsumerState<HomeView> {
  // 4. ELIMINA la lista estática 'data'
  // final data = <SectionData>[ ... ]; // <--- BORRAR ESTO

  int iCurrentSection = 0;
  final heightFirstBox = 56.0;
  final heightSection = 816.0;
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // 5. Mueve el listener al 'didChangeDependencies' o 'build'
    //    para asegurar que 'ref' esté disponible si es necesario,
    //    aunque aquí no usa 'ref', es buena práctica.
    scrollCtrl.addListener(scrollListener);
  }

  void scrollListener() {
    // 6. Obtén la lista de secciones desde el provider (para saber su 'length')
    //    Usamos 'ref.read' porque estamos en un callback, no en 'build'.
    final sectionsAsync = ref.read(homeViewModelProvider);

    // Solo calcula si hay datos
    sectionsAsync.whenData((sections) {
      final currentScroll = scrollCtrl.position.pixels - heightFirstBox - 24.0;
      int index = (currentScroll / heightSection).floor();
      if (index < 0) index = 0;
      if (index >= sections.length) {
        // Usa sections.length
        index = sections.length - 1;
      }
      if (index != iCurrentSection) setState(() => iCurrentSection = index);
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
    // 7. OBSERVA el provider. 'ref.watch' reconstruirá la vista
    //    cuando el estado cambie (loading, data, error)
    final sectionsAsync = ref.watch(homeViewModelProvider);

    return Scaffold(
      // 8. Usa 'when' para manejar los estados de carga
      body: sectionsAsync.when(
        // --- Estado: Datos cargados ---
        data: (sections) {
          // 'sections' es tu List<SectionData> desde Supabase
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
              ListView.separated(
                controller: scrollCtrl,
                itemBuilder: (_, i) => i == 0
                    ? SizedBox(height: heightFirstBox)
                    // 9. Usa los datos de 'sections'
                    : Section(data: sections[i - 1]),
                separatorBuilder: (_, i) => const SizedBox(height: 24.0),
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
                // 10. Usa el 'length' de los datos de 'sections'
                itemCount: sections.length + 1,
              ),
              Positioned(
                top: 40.0,
                left: 0,
                right: 0,
                // 11. Asegúrate de que iCurrentSection sea válido
                child: CurrentSection(
                  data: sections[iCurrentSection.clamp(0, sections.length - 1)],
                ),
              ),
            ],
          );
        },
        // --- Estado: Cargando ---
        loading: () => const Center(child: CircularProgressIndicator()),
        // --- Estado: Error ---
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
                  'ETAPA ${data.etapa}, SECCIÓN ${data.seccion}',
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
            // child: SvgPicture.asset(
            //   'assets/leccion.svg',
            //   width: 20,
            //   height: 20,
            // ),
          ),
        ],
      ),
    );
  }
}
