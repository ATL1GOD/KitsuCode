import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class SegmentedEventProgressBar extends StatelessWidget {
  final int totalChallenges;
  final double progress;
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;
  final Color primaryColor;

  const SegmentedEventProgressBar({
    super.key,
    required this.totalChallenges,
    required this.progress,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    this.primaryColor = Colors.blue,
  });

  Widget _buildMilestone({required bool isLocked}) {
    const double size = 28.0;

    if (!isLocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: primaryColor,
            size: size * 0.6,
            weight: 800,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(77),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          color: Colors.white.withAlpha(179),
          size: size * 0.55,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 8.0;
    const double iconSize = 28.0;

    const double horizontalPadding = 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        final availableWidth = totalWidth - (horizontalPadding * 2);

        if (totalChallenges == 0) return const SizedBox();

        return SizedBox(
          height: iconSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Center(
                  child: Container(
                    height: barHeight,
                    width: availableWidth,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(51),
                      borderRadius: BorderRadius.circular(barHeight / 2),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: barHeight,

                    width: availableWidth * progress,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(128),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              ...List.generate(totalChallenges, (index) {
                final desafio = desafiosMensuales[index];
                final isCompleted = completedRetoIds.contains(desafio.idReto);
                final isLocked = !isCompleted;

                final segmentWidth = totalWidth / totalChallenges;
                final hitoPosition =
                    (segmentWidth * index) +
                    (segmentWidth / 2) -
                    (iconSize / 2);

                return Positioned(
                  left: hitoPosition.clamp(0.0, totalWidth - iconSize),
                  top: 0,
                  bottom: 0,
                  child: _buildMilestone(isLocked: isLocked),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
