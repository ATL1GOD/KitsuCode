import 'package:flutter/material.dart';

class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          // Divisor "or log in with"
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.black26)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "o inicia sesión con",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Expanded(child: Divider(color: Colors.black26)),
            ],
          ),
          const SizedBox(height: 20),

          // Botones de redes sociales
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton('g_logo.png'), // Reemplazar con tu asset
              const SizedBox(width: 20),
              _buildSocialButton('m_logo.png'), // Reemplazar con tu asset
            ],
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para crear cada botón social
  Widget _buildSocialButton(String assetName) {
    return InkWell(
      onTap: () {
        // Lógica de inicio de sesión social
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Image.asset(
          'assets/$assetName', // Asegúrate de tener estas imágenes en tu carpeta assets
          height: 24,
          width: 24,
        ),
      ),
    );
  }
}
