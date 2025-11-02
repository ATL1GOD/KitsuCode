import 'package:flutter/material.dart';

class PlaceholderLoader extends StatelessWidget {
  final String retoId;
  final String dinamica;

  const PlaceholderLoader({
    super.key,
    required this.retoId,
    required this.dinamica,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cargador de $dinamica')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Esta es la pantalla para la dinámica "$dinamica"\n(Reto ID: $retoId)\n\n¡Reemplaza este widget por tu cargador real!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
