import 'package:flutter/material.dart';
// Importamos los widgets desde su nueva ubicación.
import 'package:kitsucode/features/home/view/widgets/map_home.dart';

// Función auxiliar para oscurecer colores.
Color _darkenColor(Color color, double factor) {
  return HSLColor.fromColor(color)
      .withLightness(
        (HSLColor.fromColor(color).lightness - factor).clamp(0.0, 1.0),
      )
      .toColor();
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Usamos los datos de tu versión más reciente.
  final data = <SectionData>[
    SectionData(
      color: const Color(0xFF58CC02),
      colorOscuro: _darkenColor(const Color(0xFF58CC02), 0.1),
      etapa: 1,
      seccion: 1,
      titulo: 'Fundamentos de Nieve',
    ),
    SectionData(
      color: const Color(0xFF1CB0F6),
      colorOscuro: _darkenColor(const Color(0xFF1CB0F6), 0.1),
      etapa: 1,
      seccion: 2,
      titulo: "Aventura Congelada",
    ),
    SectionData(
      color: const Color(0xFFFF9600),
      colorOscuro: _darkenColor(const Color(0xFFFF9600), 0.1),
      etapa: 1,
      seccion: 3,
      titulo: "Reto del Vértice",
    ),
    SectionData(
      color: const Color.fromARGB(255, 204, 36, 226),
      colorOscuro: _darkenColor(const Color.fromARGB(255, 238, 26, 174), 0.1),
      etapa: 1,
      seccion: 3,
      titulo: "Reto del Vértice",
    ),
  ];

  // Se restaura toda la lógica de control de scroll del primer prototipo.
  int iCurrentSection = 0;
  final heightFirstBox = 56.0;
  final heightSection = 816.0; // 840 o 764.0 (altura del Section)
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(scrollListener);
  }

  void scrollListener() {
    final currentScroll = scrollCtrl.position.pixels - heightFirstBox - 24.0;
    int index = (currentScroll / heightSection).floor();
    if (index < 0) index = 0;
    if (index >= data.length) {
      index = data.length - 1; // Prevenir errores de rango.
    }
    if (index != iCurrentSection) setState(() => iCurrentSection = index);
  }

  @override
  void dispose() {
    scrollCtrl.removeListener(scrollListener);
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se restaura el Scaffold completo del diseño original.
    return Scaffold(
      body: Stack(
        children: [
          // Capa 1: El nuevo fondo de imagen repetitivo.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/home/camino.png'),
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeatY,
              ),
            ),
          ),
          // Capa 2: El camino de lecciones (ListView).
          ListView.separated(
            controller: scrollCtrl,
            itemBuilder: (_, i) => i == 0
                ? SizedBox(
                    height: heightFirstBox,
                  ) // Espacio inicial para el widget flotante
                : Section(data: data[i - 1]),
            separatorBuilder: (_, i) => const SizedBox(height: 24.0),
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
            itemCount: data.length + 1,
          ),

          // Capa 3: El widget flotante que muestra la sección actual.
          Positioned(
            top: 40.0,
            left: 0,
            right: 0,
            child: CurrentSection(data: data[iCurrentSection]),
          ),
        ],
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
