// lib/features/puzzle_game/view/puzzle_view.dart
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

// --- ¡CAMBIO 1! (Importaciones para el Tema y el Lenguaje) ---
// Estas importaciones arreglarán el error 'undefined_method'
import 'package:kitsucode/core/utils/app_themes.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// --- FIN CAMBIO 1 ---


// --- 1. DEFINIMOS LA VISTA DEL PUZZLE ---
class PuzzleView extends ConsumerWidget {
  const PuzzleView({super.key});

  // --- ¡CAMBIO 2! (Función Helper para obtener el Tema) ---
  // Esta función SÍ usa tu clase AppThemes
  ThemeData _getLanguageTheme(String langName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return isDark ? AppThemes.pythonDarkTheme : AppThemes.pythonTheme;
      case 'c':
        return isDark ? AppThemes.cDarkTheme : AppThemes.cTheme;
      case 'java':
        return isDark ? AppThemes.javaDarkTheme : AppThemes.javaTheme;
      default:
        // Fallback al tema principal si no se reconoce el lenguaje
        return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    }
  }
  // --- FIN CAMBIO 2 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // --- ¡CAMBIO 3! (Obtener el tema del lenguaje actual) ---
    // 1. Observamos el estado del AppBar para saber el lenguaje
    final appBarState = ref.watch(appBarProvider);

    // 2. Obtenemos el tema (ThemeData) usando nuestra nueva función helper
    final challengeTheme = _getLanguageTheme(
      appBarState.languageName, 
      Theme.of(context).brightness, // Mantenemos el modo claro/oscuro
    );
    
    // 3. Usamos el 'colorScheme' del TEMA DEL LENGUAJE
    final colorScheme = challengeTheme.colorScheme;
    // --- FIN CAMBIO 3 ---
    
    // 2. Leemos el estado y el notifier del provider
    final puzzleState = ref.watch(puzzleProvider);
    final puzzleNotifier = ref.read(puzzleProvider.notifier);

    // 3. Manejo de estados: carga, error, datos
    if (puzzleState.isLoading) {
      // --- ¡CAMBIO 4! (Envolver en el Tema) ---
      // También envolvemos los estados de 'loading' y 'error'
      return Theme(
        data: challengeTheme,
        child: Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (puzzleState.error != null) {
      return Theme(
        data: challengeTheme,
        child: Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
            child: Text("Error al cargar el reto: ${puzzleState.error}"),
          ),
        ),
      );
    }
    // --- FIN CAMBIO 4 ---

    // Si llegamos aquí, tenemos datos válidos
    final challenge = puzzleState.challenge!;
    final bool isPuzzleComplete = !puzzleState.filledBlanks.containsValue(null);

    // --- ¡CAMBIO 5! (Envolver el Scaffold principal en el Tema) ---
    return Theme(
      data: challengeTheme,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow, 
        appBar: AppBar(
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
          title: const Text(''),
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
        
        bottomNavigationBar: PuzzleBottomBar(
          isButtonEnabled: isPuzzleComplete,
          onCheckPressed: () { 
            puzzleNotifier.checkSolution();
            final esCorrecto = ref.read(puzzleProvider).status == PuzzleStatus.correct;
            
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) {
                // --- ¡CAMBIO 6! (Envolvemos el Feedback en el Tema) ---
                return Theme(
                  data: challengeTheme,
                  child: PuzzleFeedbackWidget(
                    isCorrect: esCorrecto,
                    onContinue: () {
                      context.pop(); // Cierra el pop-up
                      
                      //if (esCorrecto) {
                        context.go('/home');
                      //}
                    },
                  ),
                );
                // --- FIN CAMBIO 6 ---
              },
            );
          },
        ),
      ),
    );
    // --- FIN CAMBIO 5 ---
  }
}