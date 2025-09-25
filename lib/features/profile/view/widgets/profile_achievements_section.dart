// lib/features/profile/view/widgets/profile_achievements_section.dart

import 'package:flutter/material.dart';

class ProfileAchievementsSection extends StatelessWidget {
  const ProfileAchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      'assets/images/avatar_placeholder.png',
      'assets/images/login_zorro.png',
      'assets/images/avatar_placeholder.png',
      'assets/images/login_zorro.png',
      'assets/images/avatar_placeholder.png',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 30.0), // Más padding abajo
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Logros',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF4F4F4F),
                ),
              ),
              // BOTÓN MEJORADO
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                // AHORA USAMOS SOMBRA EN LUGAR DE BORDE
                return Card(
                  color: const Color(0xFFF1E1D0).withOpacity(0.8),
                  elevation: 2,
                  shadowColor: const Color(0xFFD28F4D).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: SizedBox(
                    width: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(achievements[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}