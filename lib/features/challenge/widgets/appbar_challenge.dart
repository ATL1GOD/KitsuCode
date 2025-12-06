import 'package:flutter/material.dart';

class ChallengeAppBar1 extends StatelessWidget implements PreferredSizeWidget {
  final double progress;

  final VoidCallback? onClose;

  const ChallengeAppBar1({super.key, required this.progress, this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,

      leading: onClose != null
          ? IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurface),
              onPressed: onClose,
            )
          : null,

      title: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(width: 50),
        ],
      ),

      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ChallengeAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final double progress;

  final VoidCallback? onClose;

  const ChallengeAppBar2({super.key, required this.progress, this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,

      leading: onClose != null
          ? IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurface),
              onPressed: onClose,
            )
          : null,
      title: null,
      centerTitle: false,

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4.0),
        child: LinearProgressIndicator(
          value: progress,

          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
