// lib/features/profile/view/widgets/profile_header.dart

import 'package:flutter/material.dart'; // <-- LA LÍNEA MÁGICA Y CORRECTA
// 1. Importamos nuestro modelo de datos
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:go_router/go_router.dart';

class ProfileHeader extends StatelessWidget {
  // 2. Le decimos al widget que va a recibir un objeto UserProfileModel
  final UserProfileModel userProfile;

  // 3. Hacemos que sea obligatorio pasárselo en el constructor
  const ProfileHeader({super.key, required this.userProfile});


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        // Usamos un Stack para apilar el resplandor y la imagen con borde
        Stack(
          alignment: Alignment.center,
          children: [
            // --- CAPA 1: El Resplandor ---
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEDA85E).withOpacity(0.7),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // --- CAPA 2: La Imagen con su Borde ---
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFD28F4D),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: Image.asset(
                  userProfile.avatarUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // El botón
        ElevatedButton(
          onPressed: () {
            context.go('/edit-profile', extra: userProfile);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF6C00),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            elevation: 5,
          ),
          child: const Text(
            'Editar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}