// features/columnas_game/view/columnas_view.dart

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
  // Lista de todas las "burbujas"
  List<ChallengeItem> _items = [];

  // El item que el usuario ha seleccionado
  ChallengeItem? _selectedItem;

  // Los IDs de los pares que ya han sido resueltos
  final Set<int> _solvedPairIds = {};

  // Para el feedback de error
  bool _isIncorrect = false;
  ChallengeItem? _incorrectItem1;
  ChallengeItem? _incorrectItem2;

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
    // 1. Crea las "burbujas"
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
    // No hacer nada si ya está resuelto o si estamos en animación de error
    if (_solvedPairIds.contains(tappedItem.pairId) || _isIncorrect) {
      return;
    }

    setState(() {
      if (_selectedItem == null) {
        // --- Primer item seleccionado ---
        _selectedItem = tappedItem;
        _incorrectItem1 =
            null; // Limpiar errores anteriores si selecciona de nuevo
        _incorrectItem2 = null;
      } else {
        // --- Segundo item seleccionado (comparar) ---

        bool isCorrectPair =
            _selectedItem!.pairId == tappedItem.pairId &&
            _selectedItem!.type != tappedItem.type;

        if (isCorrectPair) {
          // --- ¡Correcto! ---
          _solvedPairIds.add(tappedItem.pairId);
          _selectedItem = null; // Limpiar selección

          // Comprobar si ganó
          if (_solvedPairIds.length == widget.challenge.pares.length) {
            // Pequeño delay para que el usuario vea el par correcto antes del modal
            Future.delayed(const Duration(milliseconds: 300), () {
              _showWinDialog();
            });
          }
        } else if (_selectedItem == tappedItem) {
          // --- Deseleccionar ---
          _selectedItem = null;
        } else {
          // --- ¡Incorrecto! ---
          // Guardamos los dos items incorrectos
          _incorrectItem1 = _selectedItem;
          _incorrectItem2 = tappedItem;
          _selectedItem = null; // Limpiamos la selección
          _triggerIncorrectAnimation(); // Llamamos a la animación
        }
      }
    });
  }

  void _triggerIncorrectAnimation() {
    setState(() {
      _isIncorrect = true;
    });

    // Feedback visual rojo
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _isIncorrect = false;
        _incorrectItem1 = null; // Limpiar items incorrectos
        _incorrectItem2 = null;
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
    // Calculamos el progreso
    double progress = _solvedPairIds.length / widget.challenge.pares.length;
    bool isComplete = progress == 1.0;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco como en la imagen
      // AppBar simulada en el body para control total
      body: SafeArea(
        child: Column(
          children: [
            // --- Barra de progreso y Salir ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green,
                        minHeight: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.flash_on, color: Colors.pink, size: 20),
                  const Text(
                    ' ∞',
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- Título ---
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona los pares', // Título de la imagen
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3C3C), // Color oscuro, no blanco
                  ),
                ),
              ),
            ),

            // --- Grid de Botones ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  key: const ValueKey('grid_view'), // Key para estabilidad
                  itemCount: _items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Dos columnas fijas
                    childAspectRatio: 2.8, // Ancho / Alto del botón
                    crossAxisSpacing: 12.0, // Espacio horizontal
                    mainAxisSpacing: 12.0, // Espacio vertical
                  ),
                  itemBuilder: (context, index) {
                    return _buildItemChip(_items[index]);
                  },
                ),
              ),
            ),

            // --- Botón de Comprobar ---
            _buildCheckButton(isComplete),
          ],
        ),
      ),
    );
  }

  // El widget para cada "burbuja" (ahora como botón de Duolingo)
  Widget _buildItemChip(ChallengeItem item) {
    final bool isSolved = _solvedPairIds.contains(item.pairId);
    final bool isSelected = _selectedItem == item;
    // Esta es la nueva lógica: solo es incorrecto si está en la lista de incorrectos
    final bool isMarkedIncorrect =
        _isIncorrect && (_incorrectItem1 == item || _incorrectItem2 == item);

    // --- Define los estilos según el estado (Estilo Duolingo Blanco) ---
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = const Color(0xFF585858);
    double elevation = 2.0;
    FontWeight fontWeight = FontWeight.bold;

    if (isSolved) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green;
      textColor = Colors.green.shade700;
      elevation = 0.0;
    } else if (isMarkedIncorrect) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red;
      textColor = Colors.red.shade700;
      elevation = 2.0;
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue;
      textColor = Colors.blue.shade700;
      elevation = 4.0;
    }

    // Botones resueltos se "desactivan"
    VoidCallback? onTap = isSolved ? null : () => _onItemTapped(item);

    return Material(
      elevation: elevation,
      color: backgroundColor, // El color de fondo va en el Material
      borderRadius: BorderRadius.circular(12.0),
      shadowColor: Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: double.infinity, // Ocupa el espacio del Grid
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: borderColor,
              width: 2.5,
            ), // Borde más grueso
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para el botón inferior "COMPROBAR"
  Widget _buildCheckButton(bool isComplete) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: isComplete
            ? () {
                // Aquí puedes llamar a _showWinDialog() o
                // a tu provider de resultados
                _showWinDialog();
              }
            : null, // Se activa solo al completar
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete ? Colors.green : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: isComplete ? 2 : 0,
        ),
        child: Text(
          'COMPROBAR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isComplete ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
