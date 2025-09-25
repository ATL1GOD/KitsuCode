// lib/features/profile/view/widgets/profile_info_card.dart

import 'package:flutter/material.dart';
// 1. Importamos nuestro modelo
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

class ProfileInfoCard extends StatelessWidget {
  // 2. Le decimos al widget que va a recibir los datos del perfil
  final UserProfileModel userProfile;

  const ProfileInfoCard({super.key, required this.userProfile});

 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Card(
        color: const Color(0xFFF1E1D0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información de perfil',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF4F4F4F),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 3. Usamos los datos del modelo en lugar de texto fijo
                  Text(
                    userProfile.nombrePerfil, // <-- DATO REAL
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '@${userProfile.nombreUsuario}', // <-- DATO REAL
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        userProfile.siguiendoCount.toString(), // <-- DATO REAL
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text('Siguiendo', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        userProfile.seguidoresCount.toString(), // <-- DATO REAL
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text('Seguidores',
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}