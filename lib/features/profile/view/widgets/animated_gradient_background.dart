// import 'package:flutter/material.dart';

// class AnimatedGradientBackground extends StatefulWidget {
//   const AnimatedGradientBackground({super.key});

//   @override
//   State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
// }

// class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Alignment> _topAlignmentAnimation;
//   late Animation<Alignment> _bottomAlignmentAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
//     _topAlignmentAnimation = TweenSequence<Alignment>([
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.topRight, end: Alignment.bottomRight), weight: 1),
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.bottomLeft, end: Alignment.topLeft), weight: 1),
//     ]).animate(_controller);

//     _bottomAlignmentAnimation = TweenSequence<Alignment>([
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.bottomLeft, end: Alignment.topLeft), weight: 1),
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
//       TweenSequenceItem(tween: Tween<Alignment>(begin: Alignment.topRight, end: Alignment.bottomRight), weight: 1),
//     ]).animate(_controller);

//     _controller.repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).colorScheme;
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [colors.secondaryContainer, colors.primaryContainer, colors.tertiaryContainer],
//               begin: _topAlignmentAnimation.value,
//               end: _bottomAlignmentAnimation.value,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }