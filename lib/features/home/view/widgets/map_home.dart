import 'package:flutter/material.dart';
import 'package:kitsucode/features/home/view/widgets/buttons_home.dart';
import 'package:kitsucode/features/home/model/home_model.dart';

class Section extends StatelessWidget {
  final SectionData data;

  const Section({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF2D3D41))),
            const SizedBox(width: 16),
            Text(
              data.titulo,
              style: const TextStyle(
                color: Color(0xFF52656D),
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Divider(color: Color(0xFF2D3D41))),
          ],
        ),
        const SizedBox(height: 24.0),
        ...List.generate(
          9,
          (i) => i % 9 != 4
              ? Container(
                  margin: EdgeInsets.only(
                    bottom: i != 8 ? 24.0 : 0,
                    left: getLeft(i),
                    right: getRight(i),
                  ),
                  child: ReliefSectionButton(
                    onPressed: () {},
                    baseColor: data.color,
                    reliefColor: data.colorOscuro,
                    svgAsset: 'images/home/estrella.svg',
                    size: 56.0,
                    reliefThickness: 6.0,
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: Image.asset(
                    'images/home/3.png',
                    width: 72,
                    height: 72,
                  ),
                ),
        ),
      ],
    );
  }

  double getLeft(int indice) {
    const margin = 72.0;
    int pos = indice % 9;
    if (pos == 1) return margin;
    if (pos == 2) return margin * 2;
    if (pos == 3) return margin;
    return 0.0;
  }

  double getRight(int indice) {
    const margin = 72.0;
    int pos = indice % 9;
    if (pos == 5) return margin;
    if (pos == 6) return margin * 2;
    if (pos == 7) return margin;
    return 0.0;
  }
}
