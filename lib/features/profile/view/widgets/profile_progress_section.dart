// lib/features/profile/view/widgets/profile_progress_section.dart

import 'package:flutter/material.dart';

class ProfileProgressSection extends StatelessWidget {
  const ProfileProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Fila del Título y botón "Ver todo" ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
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

          // --- Cuadrícula de 2x2 para las estadísticas ---
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.article_outlined,
                  value: '50',
                  label: 'Retos',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  value: '50',
                  label: 'Logros',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: null, // No lleva ícono
                  value: '20%',
                  label: 'Porcentaje fallos',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: null, // No lleva ícono
                  value: '80%',
                  label: 'Porcentaje aciertos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -- Widget Auxiliar para cada tarjeta de estadística --
class _StatCard extends StatelessWidget {
  final IconData? icon;
  final String value;
  final String label;

  const _StatCard({
    this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // AHORA USAMOS SOMBRA EN LUGAR DE BORDE
    return Card(
      color: const Color(0xFFF1E1D0).withOpacity(0.8),
      elevation: 2, // Le damos una pequeña elevación
      shadowColor: const Color(0xFFD28F4D).withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFFB86914)),
                  const SizedBox(width: 8),
                  Text('$value $label', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F4F4F))),
                ],
              )
            : Column(
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F4F4F))),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
      ),
    );
  }
}