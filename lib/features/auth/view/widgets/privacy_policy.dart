import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/view/auth_view.dart';
import 'package:kitsucode/features/auth/view/widgets/auth_background.dart'; // Reutilizamos tu fondo

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reutilizamos el tema para mantener la consistencia
    return Theme(
      data: authTheme,
      child: Scaffold(
        // Usamos AuthBackground para que el fondo sea idéntico
        body: AuthBackground(
          isScrollable: false, // <-- ¡Le decimos que NO scrollee la página!
          showFox: false,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón para cerrar y volver
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 16),
              // Contenedor del texto
              Expanded(
                // <-- ¡CLAVE! Para que llene el espacio restante
                child: Container(
                  // height: MediaQuery.of(context).size.height * 0.7, // Ya no es necesario
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withAlpha(51)),
                  ),
                  child: const SingleChildScrollView(
                    // <-- Este scroll SÍ se queda
                    padding: EdgeInsets.all(24.0),
                    child: PrivacyPolicyText(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget separado para el texto, para mantener el archivo limpio
class PrivacyPolicyText extends StatelessWidget {
  const PrivacyPolicyText({super.key});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(color: Colors.white.withAlpha(220));
    final headingStyle = TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Política de Privacidad y Términos de Uso',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aplicación móvil: Kitsucode',
          textAlign: TextAlign.center,
          style: bodyStyle,
        ),
        const SizedBox(height: 24),

        // --- 1. Introducción ---
        Text('1. Introducción', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'La presente Política de Uso y Privacidad de Datos tiene como propósito informar a los usuarios sobre el tratamiento, protección y uso de los datos personales recopilados por la aplicación móvil Kitsucode.',
          style: bodyStyle,
        ),
        Text(
          'El uso de esta aplicación implica la aceptación expresa de las condiciones establecidas en esta política.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 2. Información que Recopilamos ---
        Text('2. Información que Recopilamos', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'Kitsucode recopila únicamente los datos estrictamente necesarios para el funcionamiento de la aplicación y la gestión de tu cuenta. No solicitamos acceso a tu cámara, micrófono, contactos o ubicación.',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        Text(
          '  •  Datos de la cuenta de usuario:\n    - Correo electrónico: Utilizado como tu identificador de cuenta, para inicio de sesión y recuperación de contraseña.\n    - Contraseña: Almacenada de forma segura y encriptada.',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        Text(
          '  •  Datos de progreso en la aplicación:\n    - Progreso en los retos de programación, puntuaciones y estadísticas de rendimiento (similar a Duolingo).',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 3. Finalidad del Tratamiento de Datos ---
        Text('3. Finalidad del Tratamiento de Datos', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'Los datos recopilados serán utilizados exclusivamente para los siguientes fines:',
          style: bodyStyle,
        ),
        Text(
          '  •  Autenticar tu acceso a la aplicación.\n  •  Gestionar tu cuenta y permitir la recuperación de contraseña.\n  •  Registrar y mostrar tu progreso en los retos de programación.\n  •  Mejorar el rendimiento y la estabilidad de la aplicación.',
          style: bodyStyle,
        ),
        Text(
          'En ningún caso tus datos serán utilizados con fines comerciales o de publicidad de terceros.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 4. Conservación y 5. Transferencia ---
        Text('4. Uso y Conservación de los Datos', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'Los datos personales serán almacenados en servidores seguros. El tiempo de conservación será el necesario para mantener tu cuenta activa o hasta que solicites su eliminación.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),
        Text('5. Transferencia de Datos a Terceros', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'No se realizará transferencia de datos personales a terceros, excepto en caso de un requerimiento legal o judicial.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 6. Seguridad ---
        Text('6. Seguridad de la Información', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'Se implementan medidas técnicas y administrativas para proteger la información contra pérdida, uso indebido o acceso no autorizado, incluyendo el cifrado de datos.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 7. Derechos del Usuario ---
        Text('7. Derechos del Usuario', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'El usuario podrá ejercer sus derechos de Acceso, Rectificación, Cancelación y Oposición (ARCO) respecto al tratamiento de sus datos, enviando una solicitud al correo electrónico:',
          style: bodyStyle,
        ),
        Text('📧 isagi1yoishi0@gmail.com', style: bodyStyle),
        const SizedBox(height: 16),

        // --- 8. Uso Responsable ---
        Text('8. Uso Responsable de la Aplicación', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'El usuario se compromete a:\n  •  Utilizar la aplicación con fines de aprendizaje y práctica.\n  •  No intentar alterar el funcionamiento de la app con fines engañosos.\n  •  Mantener la seguridad de su contraseña.',
          style: bodyStyle,
        ),
        Text(
          'El mal uso de la aplicación podrá derivar en la suspensión del acceso a la cuenta.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 9. Cambios en la Política ---
        Text('9. Cambios en la Política de Privacidad', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          'Kitsucode se reserva el derecho de modificar esta política. Las modificaciones serán notificadas dentro de la aplicación.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        // --- 10. Contacto ---
        Text('10. Contacto', style: headingStyle),
        const SizedBox(height: 8),
        Text('Proyecto: Kitsucode', style: bodyStyle),
        Text('📧 isagi1yoishi0@gmail.com', style: bodyStyle),
      ],
    );
  }
}
