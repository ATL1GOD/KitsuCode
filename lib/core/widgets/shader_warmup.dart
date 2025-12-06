import 'dart:ui';
import 'package:flutter/material.dart';

class ShaderWarmUp extends StatelessWidget {
  const ShaderWarmUp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Offstage(
      offstage: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              _buildBlurWarmup(5.0),
              _buildBlurWarmup(8.0),
              _buildBlurWarmup(10.0),
              _buildBlurWarmup(15.0),

              _buildShadowWarmup(colors.primary, 8.0),
              _buildShadowWarmup(colors.secondary, 16.0),
              _buildShadowWarmup(Colors.black, 4.0),

              _buildGradientWarmup([
                colors.primary,
                colors.secondary,
                colors.tertiary,
              ]),

              _buildColorFilterWarmup(colors.primary, BlendMode.srcIn),
              _buildColorFilterWarmup(colors.secondary, BlendMode.multiply),
              _buildColorFilterWarmup(colors.tertiary, BlendMode.overlay),

              Opacity(
                opacity: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withAlpha(77),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withAlpha(153),
                        colors.secondary.withAlpha(153),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurWarmup(double sigma) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(color: Colors.transparent, width: 10, height: 10),
    );
  }

  Widget _buildShadowWarmup(Color color, double blurRadius) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(128),
            blurRadius: blurRadius,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientWarmup(List<Color> colors) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  Widget _buildColorFilterWarmup(Color color, BlendMode blendMode) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, blendMode),
      child: Container(width: 10, height: 10, color: Colors.white),
    );
  }
}
