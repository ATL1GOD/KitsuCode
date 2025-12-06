import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

enum ConnectivityStatus { online, offline, checking }

final connectivityProvider = StreamProvider.autoDispose<ConnectivityStatus>((
  ref,
) async* {
  await ref.watch(bootstrapProvider.future);

  final connectivity = Connectivity();

  try {
    final initialState = await ref.watch(initialConnectivityProvider.future);
    yield initialState;
  } catch (e) {
    yield ConnectivityStatus.offline;
  }

  await for (final result in connectivity.onConnectivityChanged) {
    if (result.contains(ConnectivityResult.none)) {
      yield ConnectivityStatus.offline;
      continue;
    }

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

final initialConnectivityProvider = FutureProvider<ConnectivityStatus>((
  ref,
) async {
  await ref.watch(bootstrapProvider.future);

  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();

  if (result.contains(ConnectivityResult.none)) {
    return ConnectivityStatus.offline;
  }

  try {
    final hasInternet = await _checkSupabaseConnection();
    return hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline;
  } catch (e) {
    return ConnectivityStatus.offline;
  }
});

Future<bool> _checkSupabaseConnection() async {
  try {
    final supabase = Supabase.instance.client;

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

final isRecoveringFromOfflineProvider = StateProvider<bool>((ref) => false);
