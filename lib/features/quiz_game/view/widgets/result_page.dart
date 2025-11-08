// // lib/features/quiz_game/view/widgets/result_page.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/core/utils/app_colors.dart'; 

// import 'package:kitsucode/features/challenge/repository/challenge_repository.dart';
// import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// import 'package:kitsucode/features/competences/provider/ranking_provider.dart';

// import 'package:go_router/go_router.dart';
// import 'package:kitsucode/features/challenge/widgets/challenge_feedback_modal.dart';
// import 'package:kitsucode/core/utils/app_themes.dart';

// // --- NUEVO: Import para el modelo de recursos ---
// import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;


// class QuizResultPage extends ConsumerStatefulWidget {
//   final int marks;
//   final int totalQuestions;
//   final int durationInSeconds;
//   final String retoId; 
//   // --- NUEVO ---
//   final List<RecursoModel> recursos;

//   const QuizResultPage({
//     super.key,
//     required this.marks,
//     required this.totalQuestions,
//     required this.durationInSeconds,
//     required this.retoId,
//     required this.recursos, // <-- AÑADIDO
//   });

//   @override
//   ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
// }

// class _QuizResultPageState extends ConsumerState<QuizResultPage> {
//   final List<String> images = [
//     "assets/images/success.png",
//     "assets/images/good.png",
//     "assets/images/bad.png",
//   ];

//   late String image;
//   late int percentage;
//   late String formattedTime;
  
//   // --- NUEVO ---
//   bool _hasSubmitted = false; // Para evitar doble envío

//   @override
//   void initState() {
//     super.initState();
    
//     final double scoreRatio = widget.marks / (widget.totalQuestions * 5);
//     if (scoreRatio < 0.5) {
//       image = images[2]; // bad
//     } else if (scoreRatio < 0.8) {
//       image = images[1]; // good
//     } else {
//       image = images[0]; // success
//     }

//     percentage = (scoreRatio * 100).round();

//     final int minutes = widget.durationInSeconds ~/ 60;
//     final int seconds = widget.durationInSeconds % 60;
//     formattedTime =
//         "${minutes.toString()}:${seconds.toString().padLeft(2, '0')}";
        
//     // --- MODIFICADO: YA NO enviamos el intento desde aquí ---
//     /*
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _submitAttempt();
//     });
//     */
//   }

//   // --- MODIFICADO: Esta función ya no es necesaria aquí ---
//   /*
//   Future<void> _submitAttempt() async {
//     // ... (toda la función eliminada)
//   }
//   */

//   // --- (Tu función _getLanguageTheme no cambia) ---
//   ThemeData _getLanguageTheme(String langName, Brightness brightness) {
//     final isDark = brightness == Brightness.dark;
    
//     // Asumiendo que tienes AppThemes.
//     switch (langName.toLowerCase().trim()) {
//       case 'python':
//         return isDark ? AppThemes.pythonDarkTheme : AppThemes.pythonTheme;
//       case 'c':
//         return isDark ? AppThemes.cDarkTheme : AppThemes.cTheme;
//       case 'java':
//         return isDark ? AppThemes.javaDarkTheme : AppThemes.javaTheme;
//       default:
//         return isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
//     }
//   }

//   // --- ¡¡AQUÍ ESTÁ LA MAGIA Y LA CORRECCIÓN DEL BUG!! ---
//   void _showFeedbackModal() {
//     // No mostrar el modal de nuevo si ya se envió
//     if (_hasSubmitted) return; 
    
//     final bool esCorrecto = (percentage > 50);

//     final appBarState = ref.read(appBarProvider);
//     final challengeTheme = _getLanguageTheme(
//       appBarState.languageName,
//       Theme.of(context).brightness,
//     );

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (ctx) { // 'ctx' es el contexto del BottomSheet
//         return Theme(
//           data: challengeTheme,
//           child: ChallengeFeedbackModal(
//             isCorrect: esCorrecto,
//             // --- ¡¡¡ESTA ES LA CORRECCIÓN DEFINITIVA!!! ---
//             onContinue: () async {
              
//               // NAVEGACIÓN 1: Cierra el modal (usando el contexto del modal 'ctx')
//               Navigator.of(ctx).pop(); 
              
//               if (_hasSubmitted) return;
//               _hasSubmitted = true; // Marcamos como enviado

//               final repository = ref.read(challengeRepositoryProvider);
//               final int retoIdAsInt = int.parse(widget.retoId);

//               if (esCorrecto) {
//                 // 1. Enviar intento y obtener trofeos (await)
//                 final int trofeos = await repository.submitChallengeAttempt(
//                   retoId: retoIdAsInt,
//                   fueExitoso: true,
//                   tiempoQueTardo: widget.durationInSeconds, 
//                 );
                
//                 // 2. Refrescar stats y ranking
//                 ref.read(appBarProvider.notifier).fetchStats();
//                 ref.invalidate(globalRankingProvider);
                
//                 // 3. NAVEGACIÓN 2 (Push a la nueva vista)
//                 // (usando el 'context' de la página)
//                 if (!context.mounted) return;
//                 context.push('/challenge_success', extra: trofeos);
              
//               } else {
//                 // 1. Enviar intento fallido (await)
//                  await repository.submitChallengeAttempt(
//                   retoId: retoIdAsInt,
//                   fueExitoso: false,
//                   tiempoQueTardo: widget.durationInSeconds,
//                 );

//                 // 2. Refrescar stats (vidas)
//                 ref.read(appBarProvider.notifier).fetchStats();

//                 // 3. Obtener recursos del widget
//                 final List<RecursoModel> recursos = widget.recursos;
                
//                 // 4. NAVEGACIÓN 2 (Push a la nueva vista)
//                 if (!context.mounted) return;
//                 context.push('/challenge_failure', extra: recursos);
//               }
//             },
//             // --- FIN MODIFICACIÓN ---
//           ),
//         );
//       },
//     );
//   }
//   // --- FIN NUEVO ---

//   @override
//   Widget build(BuildContext context) {
//     // ... tu lógica de 'brightness' y 'colorScheme' ...
//     final brightness = MediaQuery.of(context).platformBrightness;
//     final colorScheme = (brightness == Brightness.dark)
//         ? pythonDarkColorScheme
//         : pythonLightColorScheme;

//     return Theme(
//       data: ThemeData.from(colorScheme: colorScheme, useMaterial3: true),
//       child: Scaffold(
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 24.0,
//               vertical: 16.0,
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: <Widget>[
//                 const Spacer(),
//                 Image.asset(image, height: 200, fit: BoxFit.contain),
//                 const SizedBox(height: 24),
//                 Text(
//                   '¡Completaste la práctica!',
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: colorScheme.onSurface,
//                       ),
//                 ),
//                 const SizedBox(height: 32),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _StatCard(
//                       label: 'EXP TOTALES',
//                       value: widget.marks.toString(),
//                       icon: Icons.star_rounded,
//                       colorScheme: colorScheme,
//                     ),
//                     _StatCard(
//                       label: 'BIEN',
//                       value: '$percentage%',
//                       icon: Icons.check_circle_rounded,
//                       colorScheme: colorScheme,
//                     ),
//                     _StatCard(
//                       label: 'ÁGIL',
//                       value: formattedTime,
//                       icon: Icons.timer_rounded,
//                       colorScheme: colorScheme,
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: colorScheme.primary,
//                       foregroundColor: colorScheme.onPrimary,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                     ),
//                     // --- MODIFICADO: Lógica de onPressed ---
//                     onPressed: () {
//                       print("¡¡¡SÍ ESTOY USANDO EL CÓDIGO NUEVO - ON PRESSED!!! 🔥🔥🔥");
//                       _showFeedbackModal();
//                     },
//                     // --- FIN MODIFICADO ---
//                     child: const Text(
//                       'CONTINUAR',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   // ... (Tu widget _StatCard no cambia) ...
//   final String label;
//   final String value;
//   final IconData icon;
//   final ColorScheme colorScheme;

//   const _StatCard({
//     required this.label,
//     required this.value,
//     required this.icon,
//     required this.colorScheme,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceContainer,
//         borderRadius: BorderRadius.circular(15.0),
//         border: Border.all(color: colorScheme.outline, width: 1.5),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: colorScheme.onSurfaceVariant.withOpacity(0.8),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(icon, color: colorScheme.primary, size: 24),
//               const SizedBox(width: 8),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
