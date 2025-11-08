// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lottie/lottie.dart';

// class PuzzleFeedbackWidget extends StatelessWidget {
//   final bool isCorrect;
//   final VoidCallback onContinue;

//   const PuzzleFeedbackWidget({
//     super.key,
//     required this.isCorrect,
//     required this.onContinue,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Usamos el tema dinámico (claro/oscuro)
//     final textTheme = Theme.of(context).textTheme;
//     // Definimos colores de éxito y error
//     final Color successColor = Colors.green.shade600;
//     final Color errorColor = Colors.red.shade600;
    
//     final Color titleColor = isCorrect ? successColor : errorColor;
    
//     // animación Lottie según si es correcto o no
//     final String lottieAsset = 'assets/animations/fox_run.json';

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20).copyWith(
//         bottom: MediaQuery.of(context).padding.bottom + 20, // SafeArea
//       ),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(24),
//           topRight: Radius.circular(24),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min, // Para que no ocupe toda la pantalla
//         children: [
//           // Icono o Animación
//           SizedBox(
//             width: 120,
//             height: 120,
//             child: Lottie.asset(lottieAsset, repeat: true), // La dejamos en bucle
//           ),
//           const SizedBox(height: 20),
//           // Título
//           Text(
//             isCorrect ? "¡Respuesta Correcta!" : "Respuesta Incorrecta",
//             style: textTheme.headlineMedium?.copyWith(
//               color: titleColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           // Subtítulo 
//           Text(
//             isCorrect
//                 ? "¡Sigue así! Lo estás haciendo muy bien."
//                 : "No te preocupes. ¡Inténtalo de nuevo!",
//             style: textTheme.bodyLarge?.copyWith(
//               color: Theme.of(context).colorScheme.onSurfaceVariant,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           // Botón de continuar
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: titleColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//               ),
//             ),
//             onPressed: onContinue,
//             child: const Text(
//               'CONTINUAR',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
