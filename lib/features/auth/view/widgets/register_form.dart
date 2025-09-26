// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:kitsucode/features/auth/provider/auth_provider.dart';

// class RegisterForm extends ConsumerStatefulWidget {
//   const RegisterForm({super.key});

//   @override
//   ConsumerState<RegisterForm> createState() => _RegisterFormState();
// }

// class _RegisterFormState extends ConsumerState<RegisterForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _submit() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       final registerNotifier = ref.read(registerStateProvider.notifier);
//       final email = _emailController.text.trim();
//       final password = _passwordController.text.trim();

//       try {
//         await registerNotifier.signUpWithEmailPassword(email, password);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 'Registro exitoso. Por favor revisa tu correo para la confirmación.',
//               ),
//               backgroundColor: Colors.green,
//             ),
//           );
//           context.go('/login');
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error en el registro: ${e.toString()}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final registerState = ref.watch(registerStateProvider);
//     final colorScheme = Theme.of(context).colorScheme;

//     final inputDecoration = InputDecoration(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       filled: true,
//       fillColor: colorScheme.primary.withAlpha(30),
//     );

//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextFormField(
//             controller: _emailController,
//             decoration: inputDecoration.copyWith(hintText: 'Email'),
//             keyboardType: TextInputType.emailAddress,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Por favor ingresa un correo';
//               }
//               if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
//                 return 'Por favor ingresa un correo válido';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           TextFormField(
//             controller: _passwordController,
//             decoration: inputDecoration.copyWith(hintText: 'Contraseña'),
//             obscureText: true,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Por favor ingresa una contraseña';
//               }
//               if (value.length < 6) {
//                 return 'La contraseña debe tener al menos 6 caracteres';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           TextFormField(
//             controller: _confirmPasswordController,
//             decoration: inputDecoration.copyWith(
//               hintText: 'Confirmar Contraseña',
//             ),
//             obscureText: true,
//             validator: (value) {
//               if (value != _passwordController.text) {
//                 return 'Las contraseñas no coinciden';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: registerState.isLoading ? null : _submit,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               backgroundColor: colorScheme.primary,
//               foregroundColor: colorScheme.onPrimary,
//             ),
//             child: registerState.isLoading
//                 ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text('Crear Cuenta'),
//           ),
//           const SizedBox(height: 12),
//           TextButton(
//             onPressed: () => context.go('/login'),
//             child: Text(
//               '¿Ya tienes una cuenta? Inicia sesión',
//               style: TextStyle(color: colorScheme.primary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
