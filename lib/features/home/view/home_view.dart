// home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/features/home/view/widgets/map_home.dart';
import 'package:kitsucode/shared/appbar/kitsu_appbar.dart'; 
// import 'dart:ui'; // <--- Eliminamos esta línea, ya no se usa (corrige warning)

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int iCurrentSection = 0;
  
  // --- Valores de Posición (Están correctos) ---
  final double _changeThresholdPosition = 102.0; 
  final heightFirstBox = 192.0; 

  final List<double> _sectionOffsets = [];
  final scrollCtrl = ScrollController();
  final double _aestheticOffset = 80.0; 

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

  // (Tu función scrollListener - sin cambios)
  void scrollListener() {
    if (_sectionOffsets.isEmpty) return;
    final currentScroll = scrollCtrl.position.pixels;
    final double titleDisplayPosition =
        currentScroll + _changeThresholdPosition - _aestheticOffset; 
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

          // --- ORDEN DEL STACK ---
          // 1. Fondo de imagen (camino.png)
          // 2. ListView (círculos)
          // 3. "ESCUDO" DE IMAGEN (para tapar el scroll)
          // 4. AppBar (transparente)
          // 5. Etapa (caja verde)
          return Stack(
            children: [
              // 1. FONDO IMAGEN (La imagen de fondo principal)
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/home/camino.png'),
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeatY,
                  ),
                ),
              ),
              
              // 2. LISTVIEW (Se scrollea por detrás)
              ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0), // <-- AÑADIDO
                
                // --- ARREGLO DE ERRORES ---
                itemBuilder: (_, i) => i == 0
                    ? SizedBox(height: heightFirstBox) // <-- 192.0
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Section(data: sections[i - 1]),
                          const SizedBox(height: 100.0),
                        ],
                      ),
                separatorBuilder: (_, i) => const SizedBox(height: 24.0), // <-- AÑADIDO (corrige error)
                itemCount: sections.length + 1, // <-- AÑADIDO (corrige error)
                // --- FIN ARREGLO ---
              ),
              
              // --- 3. ¡LA SOLUCIÓN! ---
              // Este es el "escudo". Es un fondo de IMAGEN que se pone
              // encima del ListView pero debajo del AppBar.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // Su altura es la misma que la posición 'top' de la caja verde
                height: _changeThresholdPosition, // <-- 102.0
                child: Container(
                  // Usamos la MISMA imagen que el fondo (Paso 1)
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/home/camino.png'),
                      fit: BoxFit.cover,
                      // Alineamos la imagen al 'top' para que 
                      // coincida con el fondo principal
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  child: ClipRRect(), // Opcional, pero bueno tenerlo
                ),
              ),
              // --- FIN DE LA SOLUCIÓN ---

              
              // 4. APPBAR (Fijo y transparente)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: KitsuAppBar(), // <-- Tu AppBar (sigue siendo transparente)
              ),
              
              // 5. ETAPA (Fijo)
              Positioned(
                top: _changeThresholdPosition, // <-- 102.0
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
            // Puedes añadir un icono aquí
          ),
        ],
      ),
    );
  }
}