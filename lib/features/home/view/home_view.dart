// home_view.dart

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
  // final heightSection = 600.0; // Ya no se usa

  // Lista de posiciones de scroll (offsets) donde comienza el TÍTULO de cada sección.
  final List<double> _sectionOffsets = [];
  final scrollCtrl = ScrollController();

  final double _changeThresholdPosition = 40.0; // Valor de 'top' en Positioned

  // Nuevo offset de ajuste (e.g., 80.0 px) para que el cambio ocurra antes
  // de que el título llegue al umbral de 40.0.
  final double _aestheticOffset = 80.0;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSectionOffsets();
      scrollListener();
    });
  }

  void _calculateSectionOffsets() {
    final sectionsAsync = ref.read(homeViewModelProvider);

    sectionsAsync.whenData((sections) {
      if (sections.isEmpty) return;

      // El offset de inicio del título de la primera sección.
      // (heightFirstBox (56.0) + 24.0 (primer separador))
      double currentOffset = heightFirstBox + 24.0;

      _sectionOffsets.clear();
      // El TÍTULO de la primera sección empieza en 80.0
      _sectionOffsets.add(currentOffset);

      for (int i = 0; i < sections.length; i++) {
        final section = sections[i];

        // --- CORRECCIÓN DEL CÁLCULO DE ALTURA ---

        // 1. Altura del Row del título + SizedBox(24.0)
        // (Usamos 60.0 como estimación de altura del Row del título + márgenes)
        const double sectionHeaderHeight = 60.0;

        // 2. Altura del Stack de botones (cálculo IDÉNTICO al de map_home.dart)
        const double buttonHeight = 56.0 + 6.0; // 62.0
        final double stackHeight = section.levels.isEmpty
            ? 0.0
            : ((section.levels.length - 1) * 96.0 + 40.0) + buttonHeight;

        // 3. Altura total del widget Section (Header + Stack)
        double sectionWidgetHeight = sectionHeaderHeight + stackHeight;

        // 4. Altura del bloque en el ListView (Widget Section + SizedBox(100.0) + Separador(24.0))
        double totalSectionBlockHeight = sectionWidgetHeight + 100.0 + 24.0;

        // --- FIN CORRECCIÓN ---

        currentOffset += totalSectionBlockHeight;

        // El offset de la siguiente sección comienza en este punto.
        _sectionOffsets.add(currentOffset);
      }
    });
  }

  void scrollListener() {
    if (_sectionOffsets.isEmpty) return;

    final currentScroll = scrollCtrl.position.pixels;

    // CORRECCIÓN CLAVE:
    // 1. Consideramos la posición del indicador: currentScroll + _changeThresholdPosition (40.0)
    // 2. Aplicamos el _aestheticOffset: Restamos 80.0 para que el cambio ocurra antes.
    // El cambio ocurre cuando el scroll está 80.0 píxeles por encima del punto de inicio del título.
    final double titleDisplayPosition =
        currentScroll + _changeThresholdPosition - _aestheticOffset;

    int newIndex = 0;

    // Buscar el índice del título que ha pasado el umbral ajustado.
    for (int i = _sectionOffsets.length - 1; i >= 0; i--) {
      // Si la posición de detección ajustada es mayor o igual al punto de inicio del título de la sección 'i'.
      if (titleDisplayPosition >= _sectionOffsets[i]) {
        newIndex = i;
        break;
      }
    }

    final sections = ref.read(homeViewModelProvider).value ?? [];
    newIndex = newIndex.clamp(0, sections.length - 1);

    if (newIndex != iCurrentSection) {
      setState(() => iCurrentSection = newIndex);
    }
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
          if (sections.isNotEmpty &&
              (_sectionOffsets.isEmpty ||
                  _sectionOffsets.length != sections.length + 1)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _calculateSectionOffsets(),
            );
          }

          if (sections.isEmpty) {
            return const Center(child: Text("No hay secciones disponibles."));
          }

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/home/camino.png'),
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              ),
              ListView.separated(
                controller: scrollCtrl,
                itemBuilder: (_, i) => i == 0
                    ? SizedBox(height: heightFirstBox)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Section(data: sections[i - 1]),
                          const SizedBox(height: 100.0),
                        ],
                      ),
                separatorBuilder: (_, i) => const SizedBox(height: 24.0),
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
                itemCount: sections.length + 1,
              ),
              Positioned(
                top: _changeThresholdPosition, // 40.0
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
