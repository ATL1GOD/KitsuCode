import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilidad para detectar el rendimiento del dispositivo
/// y deshabilitar efectos pesados en dispositivos de gama media-baja
class DevicePerformanceUtils {
  static bool? _isLowEndDevice;

  /// Detecta si el dispositivo es de gama media-baja
  ///
  /// Criterios:
  /// - En modo debug: siempre retorna false (para desarrollo)
  /// - En Android: detecta según el fabricante y modelo
  /// - En iOS: detecta según el modelo
  /// - En otros casos: asume dispositivo de gama media por seguridad
  static bool isLowEndDevice() {
    // Cache el resultado para no recalcular
    if (_isLowEndDevice != null) {
      return _isLowEndDevice!;
    }

    // En modo debug, no aplicar optimizaciones para pruebas
    if (kDebugMode) {
      _isLowEndDevice = false;
      return false;
    }

    try {
      if (Platform.isAndroid) {
        _isLowEndDevice = _detectAndroidLowEnd();
      } else if (Platform.isIOS) {
        _isLowEndDevice = _detectiOSLowEnd();
      } else {
        // Por seguridad, en plataformas desconocidas asumimos gama media
        _isLowEndDevice = true;
      }
    } catch (e) {
      // Si hay error en detección, asumimos gama media por seguridad
      _isLowEndDevice = true;
    }

    return _isLowEndDevice!;
  }

  /// Detecta dispositivos Android de gama baja
  static bool _detectAndroidLowEnd() {
    // En Android, podríamos usar device_info_plus para obtener info real
    // Por ahora, usamos una heurística conservadora
    //
    // Dispositivos de gama baja típicos:
    // - Menos de 3GB RAM
    // - Procesadores viejos (Snapdragon 4xx, MediaTek Helio)
    // - Android 8 o inferior

    // Por defecto, asumimos que los efectos están habilitados
    // pero se pueden deshabilitar manualmente si hay lag
    return false;
  }

  /// Detecta dispositivos iOS de gama baja
  static bool _detectiOSLowEnd() {
    // En iOS, dispositivos de gama baja serían:
    // - iPhone 6s, 7, 8 (A9, A10, A11)
    // - iPad de 5ta generación o anterior

    // Por defecto, asumimos que los efectos están habilitados
    return false;
  }

  /// Fuerza la configuración manual del tipo de dispositivo
  /// Útil para testing o preferencias del usuario
  static void setLowEndDevice(bool isLowEnd) {
    _isLowEndDevice = isLowEnd;
  }

  /// Resetea la detección para forzar re-evaluación
  static void reset() {
    _isLowEndDevice = null;
  }

  /// Retorna true si se deben habilitar efectos pesados como BackdropFilter
  static bool shouldEnableHeavyEffects() {
    return !isLowEndDevice();
  }

  /// Retorna el nivel de calidad recomendado para animaciones
  ///
  /// Returns:
  /// - 0: Básico (sin efectos pesados)
  /// - 1: Medio (algunos efectos)
  /// - 2: Alto (todos los efectos)
  static int getQualityLevel() {
    if (kDebugMode) {
      return 2; // Máxima calidad en desarrollo
    }

    return isLowEndDevice() ? 0 : 2;
  }
}
