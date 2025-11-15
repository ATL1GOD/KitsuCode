// lib/core/providers/connectivity_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart'; // Importar bootstrap

/// Enum para el estado de conexión
enum ConnectivityStatus {
  online,
  offline,
  checking,
}

/// Provider que monitorea la conectividad en tiempo real
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* {
  
  // 🔥 CORRECCIÓN 1: Esperar a que bootstrap termine ANTES de hacer nada
  await ref.watch(bootstrapProvider.future);

  final connectivity = Connectivity();

  // Emitir el estado inicial verificado
  // Usamos 'initialConnectivityProvider.future' que ya tiene la lógica de espera
  try {
    final initialState = await ref.watch(initialConnectivityProvider.future);
    yield initialState;
  } catch (e) {
    yield ConnectivityStatus.offline;
  }

  // Escuchar cambios futuros
  await for (final result in connectivity.onConnectivityChanged) {
    if (result.contains(ConnectivityResult.none)) {
      yield ConnectivityStatus.offline;
      continue;
    }
    
    // Si hay conexión, verificar que realmente funcione
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final hasInternet = await _checkSupabaseConnection();
      yield hasInternet 
          ? ConnectivityStatus.online 
          : ConnectivityStatus.offline;
    } catch (e) {
      yield ConnectivityStatus.offline;
    }
  }
});

/// Provider auxiliar para el estado inicial de conectividad
final initialConnectivityProvider = FutureProvider<ConnectivityStatus>((ref) async {

  // 🔥 CORRECCIÓN 2: Asegurarse de que bootstrap haya terminado PRIMERO
  await ref.watch(bootstrapProvider.future);
  
  // --- Ahora la lógica original puede ejecutarse de forma segura ---
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  
  if (result.contains(ConnectivityResult.none)) {
    return ConnectivityStatus.offline;
  }
  
  // Verificar conexión real con Supabase (ahora es seguro)
  try {
    final hasInternet = await _checkSupabaseConnection();
    return hasInternet 
        ? ConnectivityStatus.online 
        : ConnectivityStatus.offline;
  } catch (e) {
    return ConnectivityStatus.offline;
  }
});

/// Helper privado para verificar conexión real con Supabase
Future<bool> _checkSupabaseConnection() async {
  try {
    final supabase = Supabase.instance.client;
    
    // Intenta hacer una query simple
    await supabase
        .from('usuarios')
        .select('id')
        .limit(1)
        .timeout(const Duration(seconds: 5));
    
    return true;
  } catch (e) {
    debugPrint('❌ Verificación de Supabase falló: $e');
    return false;
  }
}

/// Provider para rastrear si se está recuperando de un error de conexión
final isRecoveringFromOfflineProvider = StateProvider<bool>((ref) => false);