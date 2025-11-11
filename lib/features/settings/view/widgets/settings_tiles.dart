import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ... (SectionHeader y _BaseSettingsTile se quedan igual) ...

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme colors;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseSettingsTile extends StatelessWidget {
  final Widget child;
  final Color dynamicColor;
  final VoidCallback? onTap;

  const _BaseSettingsTile({
    required this.child,
    required this.dynamicColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface.withOpacity(.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dynamicColor.withOpacity(.6)),
        boxShadow: [
          BoxShadow(
            color: dynamicColor.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ... (SettingsNavigationTile se queda igual) ...

class SettingsNavigationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color dynamicColor;
  // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
  // Se añade '?' para hacerlo nulable
  final VoidCallback? onTap; 

  const SettingsNavigationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dynamicColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return _BaseSettingsTile(
      dynamicColor: dynamicColor,
      onTap: onTap, // Ahora acepta 'null' sin problemas
      child: Row(
        children: [
          Icon(icon, color: c.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: t.bodySmall?.copyWith(color: c.onSurface.withOpacity(.6))),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: c.onSurfaceVariant, size: 18),
        ],
      ),
    );
  }
}


// --- ¡WIDGET MODIFICADO! ---
// SettingsSwitchTile ahora toma 'title' y 'icon' como variables
class SettingsSwitchTile extends ConsumerStatefulWidget {
  // --- ¡CAMBIOS! ---
  final String title;       // Ya no es 'Modo Oscuro' fijo
  final IconData icon;      // Ya no es 'dark_mode' fijo
  // --- FIN CAMBIOS ---
  final String subtitle;
  final Color dynamicColor;
  final bool initialValue;
  final Function(bool) onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,    // ¡Añadido!
    required this.subtitle,
    required this.icon,     // ¡Añadido!
    required this.dynamicColor,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  ConsumerState<SettingsSwitchTile> createState() => _SettingsSwitchTileState();
}

class _SettingsSwitchTileState extends ConsumerState<SettingsSwitchTile> {
  late bool _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }
  
  // ¡Añadido! Actualiza el switch si el provider cambia
  @override
  void didUpdateWidget(covariant SettingsSwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _currentValue = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return _BaseSettingsTile(
      dynamicColor: widget.dynamicColor,
      onTap: null, 
      child: Row(
        children: [
          // --- ¡CAMBIO! ---
          Icon(widget.icon, color: c.primary, size: 28), // Usa el ícono variable
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)), // Usa el título variable
                Text(widget.subtitle, style: t.bodySmall?.copyWith(color: c.onSurface.withOpacity(.6))),
              ],
            ),
          ),
          // --- FIN CAMBIO ---
          Switch(
            value: _currentValue,
            onChanged: (newValue) {
              setState(() {
                _currentValue = newValue;
              });
              widget.onChanged(newValue);
            },
            activeThumbColor: widget.dynamicColor,
          ),
        ],
      ),
    );
  }
}

// ... (SettingsSliderTile y SettingsDestructiveTile se quedan igual) ...

class SettingsSliderTile extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final Color dynamicColor;
  final double initialValue; // 0.0 a 1.0
  final Function(double) onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.icon,
    required this.dynamicColor,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  ConsumerState<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends ConsumerState<SettingsSliderTile> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  // ¡Añadido! Actualiza el slider si el provider cambia
  @override
  void didUpdateWidget(covariant SettingsSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _currentValue = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return _BaseSettingsTile(
      dynamicColor: widget.dynamicColor,
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: c.primary, size: 28),
              const SizedBox(width: 16),
              Text(widget.title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _currentValue,
            onChanged: (newValue) {
              setState(() {
                _currentValue = newValue;
              });
            },
            // ¡CAMBIO! Usamos 'onChangeEnd' para notificar al provider
            // Esto es mejor para el rendimiento que 'onChanged'
            onChangeEnd: (newValue) {
              widget.onChanged(newValue);
            },
            activeColor: widget.dynamicColor,
            inactiveColor: widget.dynamicColor.withOpacity(0.3),
            label: "${(_currentValue * 100).toInt()}%",
            divisions: 10,
          ),
        ],
      ),
    );
  }
}


class SettingsDestructiveTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color dynamicColor;
  final VoidCallback onTap;

  const SettingsDestructiveTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dynamicColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final errorColor = c.error;

    return _BaseSettingsTile(
      dynamicColor: errorColor, // Borde rojo
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: errorColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: errorColor)),
                Text(subtitle, style: t.bodySmall?.copyWith(color: errorColor.withOpacity(.8))),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: errorColor, size: 18),
        ],
      ),
    );
  }
}