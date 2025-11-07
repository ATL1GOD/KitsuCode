// lib/features/home/view/home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/features/home/view/widgets/map_home.dart';
import 'package:kitsucode/shared/appbar/kitsu_appbar.dart';
// --- ¡CAMBIO 1! ---
// Importamos el provider del AppBar para saber el lenguaje actual
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int iCurrentSection = 0;

  final double _changeThresholdPosition = 102.0;
  final heightFirstBox = 192.0;

  final List<double> _sectionOffsets = [];
  final scrollCtrl = ScrollController();
  // final double _aestheticOffset = 80.0;

  // 🔑 CAMBIO CLAVE: Margen de anticipación (e.g., 50.0 pixeles)
  // El título de la sección cambiará 50px antes de que el nivel
  // alcance la posición de detección.
  final double _anticipationMargin = 0.1;

  // (Tu función initState - sin cambios)
  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSectionOffsets();
      scrollListener();
    });
  }

  // (Tu función _calculateSectionOffsets - sin cambios)
  void _calculateSectionOffsets() {
    final sectionsAsync = ref.read(homeViewModelProvider);

    sectionsAsync.whenData((sections) {
      if (sections.isEmpty) return;
      double currentOffset = heightFirstBox + 24.0;
      _sectionOffsets.clear();
      _sectionOffsets.add(currentOffset);
      for (int i = 0; i < sections.length; i++) {
        final section = sections[i];
        const double sectionHeaderHeight = 60.0;
        const double buttonHeight = 56.0 + 6.0; // 62.0
        final double stackHeight = section.levels.isEmpty
            ? 0.0
            : ((section.levels.length - 1) * 96.0 + 40.0) + buttonHeight;
        double sectionWidgetHeight = sectionHeaderHeight + stackHeight;
        double totalSectionBlockHeight = sectionWidgetHeight + 100.0 + 24.0;
        currentOffset += totalSectionBlockHeight;
        _sectionOffsets.add(currentOffset);
      }
    });
  }

  // 🔑 FUNCIÓN CON EL AJUSTE DEL UMBRAL
  void scrollListener() {
    if (_sectionOffsets.isEmpty) return;
    final currentScroll = scrollCtrl.position.pixels;

    // El umbral se calcula usando el desplazamiento actual,
    // la posición fija de la barra (_changeThresholdPosition),
    // y RESTANDO el margen de anticipación.
    // Esto hace que 'titleDisplayPosition' sea un valor menor,
    // forzando que el índice cambie ANTES.
    final double titleDisplayPosition =
        currentScroll + _changeThresholdPosition - _anticipationMargin;

    int newIndex = 0;
    for (int i = _sectionOffsets.length - 1; i >= 0; i--) {
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

  // (Tu función dispose - sin cambios)
  @override
  void dispose() {
    scrollCtrl.removeListener(scrollListener);
    scrollCtrl.dispose();
    super.dispose();
  }

  // (Tu función _getMapBackgroundForLanguage - sin cambios)
  String _getMapBackgroundForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return 'assets/images/home/camino5.png'; // Tu mapa de Python
      case 'java':
        return 'assets/images/home/camino.png'; // Tu mapa de Java
      case 'c':
        return 'assets/images/home/camino4.png'; // Tu mapa de C
      default:
        // Fallback por si el nombre está vacío mientras carga
        return 'assets/images/home/camino.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(homeViewModelProvider);

    // --- ¡CAMBIO 3! ---
    // Ahora TAMBIÉN observamos el appBarProvider.
    // Cuando el 'languageName' cambie, este widget se reconstruirá.
    final appBarState = ref.watch(appBarProvider);

    // Obtenemos el path del mapa dinámicamente
    final mapAssetPath = _getMapBackgroundForLanguage(appBarState.languageName);

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
            // --- ¡CAMBIO 4! ---
            // Un estado de carga mejorado mientras el appBarProvider
            // le pasa el ID al homeViewModelProvider.
            if (appBarState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Si no está cargando y no hay secciones, es que no hay datos.
            return const Center(
              child: Text("No hay secciones para este lenguaje."),
            );
          }

          return Stack(
            children: [
              // 1. FONDO IMAGEN (¡AHORA ES DINÁMICO!)
              Container(
                decoration: BoxDecoration(
                  // <-- Quitamos 'const'
                  image: DecorationImage(
                    // --- ¡CAMBIO 5! ---
                    image: AssetImage(mapAssetPath), // <-- Usamos la variable
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              ),

              // 2. LISTVIEW (Sin cambios)
              ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
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
                itemCount: sections.length + 1,
              ),

              // 3. "ESCUDO" DE IMAGEN (¡AHORA ES DINÁMICO!)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _changeThresholdPosition,
                child: Container(
                  decoration: BoxDecoration(
                    // <-- Quitamos 'const'
                    image: DecorationImage(
                      // --- ¡CAMBIO 6! ---
                      image: AssetImage(mapAssetPath), // <-- Usamos la variable
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  child: ClipRRect(),
                ),
              ),

              // 4. APPBAR (Sin cambios)
              const Positioned(top: 0, left: 0, right: 0, child: KitsuAppBar()),

              // 5. ETAPA (Sin cambios)
              Positioned(
                top: _changeThresholdPosition,
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

// (Tu clase CurrentSection sin cambios)
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
          ),
        ],
      ),
    );
  }
}
