import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart'; // Importa tu provider

class DesafiosView extends ConsumerWidget {
  const DesafiosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Desafíos'), centerTitle: true),
      body: desafiosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
        data: (desafios) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Sección de Eventos Especiales ---
              Text(
                'Eventos Especiales',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (desafios.especiales.isEmpty)
                const Text('No hay eventos especiales activos en este momento.')
              else
                // Usamos un ListView horizontal como en la maqueta
                SizedBox(
                  height: 180, // Ajusta esta altura
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: desafios.especiales.length,
                    itemBuilder: (context, index) {
                      final evento = desafios.especiales[index];
                      return EventoEspecialCard(evento: evento);
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // --- Sección de Desafíos Diarios ---
              Text(
                'Desafíos Diarios',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (desafios.diarios.isEmpty)
                const Text('No hay desafíos diarios disponibles.')
              else
                // Usamos un ListView vertical normal
                ListView.builder(
                  shrinkWrap: true, // Importante dentro de otro ListView
                  physics:
                      const NeverScrollableScrollPhysics(), // Deshabilita scroll anidado
                  itemCount: desafios.diarios.length,
                  itemBuilder: (context, index) {
                    final diario = desafios.diarios[index];
                    return DesafioDiarioCard(diario: diario);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

// --- Tarjeta para Eventos Especiales ---
class EventoEspecialCard extends StatelessWidget {
  final DesafioEspecial evento;
  const EventoEspecialCard({super.key, required this.evento});

  // Helper para formatear la duración
  String _formatTiempoRestante(Duration duration) {
    if (duration.isNegative) return "Finalizado";

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiempoRestante = evento.fechaFin.difference(DateTime.now());

    return GestureDetector(
      onTap: () {
        // Navegamos al distribuidor con el ID del reto
        context.push('/challenge/${evento.idReto}');
      },
      child: Card(
        // Ajusta el ancho de la tarjeta en la lista horizontal
        margin: const EdgeInsets.only(right: 16.0),
        child: Container(
          width: 300, // Ajusta el ancho
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aquí iría el Icono (ej. Python)
              const Icon(Icons.code, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                evento.titulo,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                evento.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Tiempo restante: ${_formatTiempoRestante(tiempoRestante)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Tarjeta para Desafíos Diarios ---
class DesafioDiarioCard extends StatelessWidget {
  final DesafioDiario diario;
  const DesafioDiarioCard({super.key, required this.diario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: const Icon(
          Icons.quiz,
          color: Colors.green,
        ), // Icono placeholder
        title: Text(diario.titulo),
        subtitle: Text('${diario.recompensaExp} XP'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navegamos al distribuidor con el ID del reto
          context.push('/challenge/${diario.idReto}');
        },
      ),
    );
  }
}
