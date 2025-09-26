import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

class ProfileInfoCard extends StatelessWidget {
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
                  // Usamos los datos del modelo en lugar de texto fijo
                  Text(
                    userProfile.nombrePerfil,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '@${userProfile.nombreUsuario}', 
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
                        userProfile.siguiendoCount.toString(), 
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text('Siguiendo', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        userProfile.seguidoresCount.toString(), 
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