// features/quiz_game/view/columns_view.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';

// (Asumiendo que tienes un provider para 'bottom_bar_provider' o similar)
// import 'package:kitsucode/shared/providers/bottom_bar_provider.dart';

class ColumnsChallengeView extends ConsumerStatefulWidget {
  final ColumnsChallenge challenge;
  final String retoId;

  const ColumnsChallengeView({
    super.key,
    required this.challenge,
    required this.retoId,
  });

  @override
  ConsumerState<ColumnsChallengeView> createState() =>
      _ColumnsChallengeViewState();
}

class _ColumnsChallengeViewState extends ConsumerState<ColumnsChallengeView> {
  // Lista de todas las "burbujas" (8 en total para 4 pares)
  List<ChallengeItem> _items = [];

  // El item que el usuario ha seleccionado
  ChallengeItem? _selectedItem;

  // Los IDs de los pares que ya han sido resueltos
  final Set<int> _solvedPairIds = {};

  // Para el 'shake' de error
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isIncorrect = false;

  @override
  void initState() {
    super.initState();
    // (Opcional: Ocultar la barra de navegación al entrar)
    // Future.microtask(() {
    //   ref.read(bottomBarVisibilityProvider.notifier).hide();
    // });

    // Prepara los items para la UI
    _setupItems();
  }

  void _setupItems() {
    // 1. Crea las 8 "burbujas" (4 terminos, 4 definiciones)
    for (var pair in widget.challenge.pares) {
      _items.add(
        ChallengeItem(
          pairId: pair.id,
          text: pair.termino,
          type: ItemType.termino,
        ),
      );
      _items.add(
        ChallengeItem(
          pairId: pair.id,
          text: pair.definicion,
          type: ItemType.definicion,
        ),
      );
    }
    // 2. ¡Baraja la lista!
    _items.shuffle(Random());
  }

  void _onItemTapped(ChallengeItem tappedItem) {
    if (_solvedPairIds.contains(tappedItem.pairId) || _isIncorrect) {
      return; // No hacer nada si ya está resuelto o si estamos en animación de error
    }

    setState(() {
      if (_selectedItem == null) {
        // --- Primer item seleccionado ---
        _selectedItem = tappedItem;
      } else {
        // --- Segundo item seleccionado (comparar) ---

        // Comprueba si son pareja (mismo ID) pero no del mismo tipo (termino/definicion)
        bool isCorrectPair =
            _selectedItem!.pairId == tappedItem.pairId &&
            _selectedItem!.type != tappedItem.type;

        if (isCorrectPair) {
          // --- ¡Correcto! ---
          _solvedPairIds.add(tappedItem.pairId);
          _selectedItem = null;

          // Comprobar si ganó
          if (_solvedPairIds.length == widget.challenge.pares.length) {
            _showWinDialog();
          }
        } else if (_selectedItem == tappedItem) {
          // --- Deseleccionar ---
          _selectedItem = null;
        } else {
          // --- ¡Incorrecto! ---
          _triggerIncorrectAnimation(tappedItem);
        }
      }
    });
  }

  // Animación simple de "shake" (opcional pero recomendada)
  void _triggerIncorrectAnimation(ChallengeItem tappedItem) {
    setState(() {
      _isIncorrect = true;
    });

    // Simula un "shake" visual (puedes usar un paquete de animación)
    // Aquí solo pondremos un delay de feedback rojo
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isIncorrect = false;
        _selectedItem = null;
      });
    });
  }

  void _showWinDialog() {
    // TODO: Implementar lógica de victoria
    // (Navegar a la pantalla de resultados, llamar a un provider, etc.)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades!'),
        content: const Text('Has completado todos los pares.'),
        actions: [
          TextButton(
            onPressed: () {
              // (Opcional: Mostrar la barra de navegación al salir)
              // ref.read(bottomBarVisibilityProvider.notifier).show();
              Navigator.of(context).pop(); // Cierra el dialogo
              Navigator.of(context).pop(); // Regresa de la pantalla del reto
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtra los items que ya están resueltos para que "desaparezcan"
    // O puedes dejarlos y solo cambiar su color.
    // ¡La UI de Duolingo los mantiene pero los "apaga"!
    // Así que mejor NO los filtraremos, solo cambiaremos su estilo.

    return Scaffold(
      backgroundColor: const Color(0xFF0A1D25), // Tu color de fondo
      appBar: AppBar(
        title: Text(widget.challenge.tituloLeccion),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Empareja los elementos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Usamos Wrap para que las burbujas fluyan
              child: Wrap(
                spacing: 12.0, // Espacio horizontal
                runSpacing: 16.0, // Espacio vertical
                alignment: WrapAlignment.center,
                children: _items.map((item) {
                  return _buildItemChip(item);
                }).toList(),
              ),
            ),
          ),
          // TODO: Añadir un botón de "Comprobar"
          // O dejar que funcione sin él, como lo hemos programado.
        ],
      ),
    );
  }

  // El widget para cada "burbuja"
  Widget _buildItemChip(ChallengeItem item) {
    final bool isSolved = _solvedPairIds.contains(item.pairId);
    final bool isSelected = _selectedItem == item;
    final bool isChecking =
        _isIncorrect && (isSelected || _selectedItem?.pairId == item.pairId);

    // --- Define los estilos según el estado ---
    Color backgroundColor = const Color(0xFF1A3A4A); // Color base
    Color borderColor = const Color(0xFF3A5F71); // Borde base
    Color textColor = Colors.white;
    double elevation = 2.0;

    if (isSolved) {
      backgroundColor = const Color(0xFF1E4B4A); // Verde oscuro "resuelto"
      borderColor = const Color(0xFF2A6A69);
      textColor = const Color(0xFF50C878); // Verde "resuelto"
      elevation = 0.0;
    } else if (isSelected) {
      backgroundColor = const Color(0xFF3A88B5); // Azul "seleccionado"
      borderColor = const Color(0xFF6ABFFF);
      elevation = 6.0;
    } else if (isChecking) {
      backgroundColor = const Color(0xFF6D2F2F); // Rojo "incorrecto"
      borderColor = const Color(0xFFE57373);
    }

    return GestureDetector(
      onTap: () => _onItemTapped(item),
      child: Material(
        elevation: elevation,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(
            item.text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
