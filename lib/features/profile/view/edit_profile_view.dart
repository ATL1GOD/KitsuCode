import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/utils/app_colors.dart'; // 1. Importamos tu paleta de colores
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

class EditProfileView extends ConsumerStatefulWidget {
  final UserProfileModel userProfile;

  const EditProfileView({super.key, required this.userProfile});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.nombrePerfil);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Obtenemos el esquema de colores del tema actual de la app
    final colors = Theme.of(context).colorScheme;
    final cardBackgroundColor = primaryLightColorScheme.primaryFixed;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 3. Usamos los colores de la paleta para el degradado
          gradient: LinearGradient(
            colors: [primaryDarkColorScheme.primary, primaryLightColorScheme.primaryFixed],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4F4F4F)),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Avatar Editable con diseño estético ---
                Stack(
                  clipBehavior: Clip.none, // Permite que el botón se salga
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: colors.secondary.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: Image.asset(
                          'assets/images/login_zorro.png', // O la imagen del usuario
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: Material(
                        color: cardBackgroundColor,
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: colors.shadow.withOpacity(0.3),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.secondary,
                          // 4. FUNCIONALIDAD DEL BOTÓN DEL LÁPIZ
                          child: IconButton(
                            icon: Icon(Icons.edit, color: colors.onSecondary, size: 20),
                            onPressed: () {
                              context.go('/edit-avatar'); // Navega a la pantalla de avatares
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- Tarjeta con el Formulario ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Card(
                    color: cardBackgroundColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Edición de perfil',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4F4F4F)),
                          ),
                          const SizedBox(height: 25),
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                            child: Text('Nombre', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                          ),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Nombre de usuario',
                              filled: true,
                              fillColor: colors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: Icon(Icons.edit, color: colors.secondary),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () => context.pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}