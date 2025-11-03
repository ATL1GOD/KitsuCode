import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart'; 
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_code_area.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_instruction_card.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_options_area.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_widgets.dart';
import 'package:kitsucode/features/puzzle_game/view/widgets/puzzle_feedback_widget.dart'; 
import 'package:animate_do/animate_do.dart';

// --- 1. DEFINIMOS LA VISTA DEL PUZZLE ---
class PuzzleView extends ConsumerWidget {
  const PuzzleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 2. Leemos el estado y el notifier del provider
    final puzzleState = ref.watch(puzzleProvider);
    final puzzleNotifier = ref.read(puzzleProvider.notifier);

    // 3. Manejo de estados: carga, error, datos
    if (puzzleState.isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (puzzleState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Text("Error al cargar el reto: ${puzzleState.error}"),
        ),
      );
    }

    // Si llegamos aquí   , tenemos datos válidos
    final challenge = puzzleState.challenge!;
    final bool isPuzzleComplete = !puzzleState.filledBlanks.containsValue(null);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow, 
      appBar: AppBar(
        // --- Lógica del AppBar 
        leadingWidth: 72,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: InkWell( 
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withAlpha(50), 
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(130))
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
              ),
            ),
          ),
        ),
        title: const Text(''), // Título vacío por ahora jaja
        centerTitle: true,
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 0.5, // TODO: Calcular esto desde el state
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary), 
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
                child: Column(
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 300),
                      child: PuzzleInstructionCard(
                        text: challenge.instruction,
                      ),
                    ),
                    const SizedBox(height: 24), 
                    FadeIn(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 150),
                      child: PuzzleCodeArea(
                        lines: challenge.lines,
                        filledBlanks: puzzleState.filledBlanks,
                        onOptionDropped: (blankId, option) {
                          puzzleNotifier.onOptionDroppedOnBlank(blankId, option);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SlideInUp(
            duration: const Duration(milliseconds: 250),
            from: 100,
            child: PuzzleOptionsArea(
              availableOptions: puzzleState.availableOptions,
              onOptionDropped: (option) {
                puzzleNotifier.onOptionDroppedOnBank(option);
              },
            ),
          ),
        ],
      ),
      
      // --- Lógica del Bottom Bar 
      bottomNavigationBar: PuzzleBottomBar(
        isButtonEnabled: isPuzzleComplete,
        onCheckPressed: () { 
          // 1. Llama al notifier
          puzzleNotifier.checkSolution();
          
          // 2.  Lee el provider simple para obtener el estado actualizado
          final esCorrecto = ref.read(puzzleProvider).status == PuzzleStatus.correct;
          
          // 3. Muestra el BottomSheet
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (ctx) {
              return PuzzleFeedbackWidget(
                isCorrect: esCorrecto,
                onContinue: () {
                  // 4. Acción al continuar aqui se implementa la navegación del guardado
                  // print("Intento guardado (simulado)");
                  context.pop(); // Cierra el pop-up
                  
                  if (esCorrecto) {
                    context.go('/home'); 
                  }
                  // Si es incorrecto, no hace nada, solo cierra el pop-up
                },
              );
            },
          );
        },
      ),
    );
  }
}