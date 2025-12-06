import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';

import 'package:kitsucode/features/auth/provider/auth_provider.dart';

const String _defaultAsset = 'assets/images/home/logo_python.webp';

@immutable
class AppBarState {
  final int lives;
  final int trophies;
  final int streak;
  final String languageName;
  final int languageId;
  final String languageAssetPath;
  final bool isLoading;

  const AppBarState({
    this.lives = 5,
    this.trophies = 0,
    this.streak = 0,
    this.languageName = '',
    this.languageId = 0,
    this.languageAssetPath = _defaultAsset,
    this.isLoading = true,
  });

  AppBarState copyWith({
    int? lives,
    int? trophies,
    int? streak,
    String? languageName,
    int? languageId,
    String? languageAssetPath,
    bool? isLoading,
  }) {
    return AppBarState(
      lives: lives ?? this.lives,
      trophies: trophies ?? this.trophies,
      streak: streak ?? this.streak,
      languageName: languageName ?? this.languageName,
      languageId: languageId ?? this.languageId,
      languageAssetPath: languageAssetPath ?? this.languageAssetPath,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppBarNotifier extends StateNotifier<AppBarState> {
  final SupabaseClient _supabase;

  AppBarNotifier(this._supabase)
    : super(
        const AppBarState(isLoading: true, languageAssetPath: _defaultAsset),
      ) {
    fetchStats();
  }

  String _getAssetForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return 'assets/images/home/logo_python.webp';
      case 'java':
        return 'assets/images/home/logo_java.webp';
      case 'c':
        return 'assets/images/home/logo_c.webp';
      default:
        return _defaultAsset;
    }
  }

  Future<void> fetchStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          languageId: 1,
          languageName: 'Python',
          languageAssetPath: _getAssetForLanguage('Python'),
          lives: 0,
          streak: 0,
          trophies: 0,
        );
        return;
      }

      final userData = await _supabase
          .from('usuarios')
          .select('lenguaje_favorito')
          .eq('id', user.id)
          .maybeSingle();

      final langId = (userData?['lenguaje_favorito'] ?? 1) as int;

      final responses = await Future.wait<dynamic>([
        _supabase.rpc(
          'get_my_language_score',
          params: {'p_language_id': langId},
        ),
        _supabase
            .from('estadistica_usuario')
            .select('racha_dias, vidas')
            .eq('id_usuario', user.id)
            .maybeSingle(),
        _supabase
            .from('lenguaje')
            .select('nombre')
            .eq('id_lenguaje', langId)
            .single(),
      ]);

      final totalTrofeos = (responses[0] as num?)?.toInt() ?? 0;

      final statsData = responses[1] as Map<String, dynamic>?;
      final racha = statsData?['racha_dias'] ?? 0;
      final vidas = statsData?['vidas'] ?? 5;

      final langData = responses[2] as Map<String, dynamic>;
      final langName = (langData['nombre'] as String).trim();
      final langAsset = _getAssetForLanguage(langName);

      state = state.copyWith(
        lives: vidas,
        trophies: totalTrofeos,
        streak: racha,
        languageName: langName,
        languageId: langId,
        languageAssetPath: langAsset,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error AppBarNotifier: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchStatsForLanguage(int langId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final responses = await Future.wait<dynamic>([
        _supabase.rpc(
          'get_my_language_score',
          params: {'p_language_id': langId},
        ),
        _supabase
            .from('estadistica_usuario')
            .select('racha_dias, vidas')
            .eq('id_usuario', user.id)
            .maybeSingle(),
        _supabase
            .from('lenguaje')
            .select('nombre')
            .eq('id_lenguaje', langId)
            .single(),
      ]);

      final totalTrofeos = (responses[0] as num?)?.toInt() ?? 0;

      final statsData = responses[1] as Map<String, dynamic>?;
      final racha = statsData?['racha_dias'] ?? 0;
      final vidas = statsData?['vidas'] ?? 5;

      final langData = responses[2] as Map<String, dynamic>;
      final langName = (langData['nombre'] as String).trim();
      final langAsset = _getAssetForLanguage(langName);

      debugPrint(
        '🔥 fetchStatsForLanguage - Lang: $langName, Trofeos: $totalTrofeos',
      );

      state = state.copyWith(
        lives: vidas,
        trophies: totalTrofeos,
        streak: racha,
        languageName: langName,
        languageId: langId,
        languageAssetPath: langAsset,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetchStatsForLanguage: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateLanguage(String newName, int newId) async {
    final newAsset = _getAssetForLanguage(newName);

    debugPrint('🔥 updateLanguage - Cambiando a: $newName (ID: $newId)');

    state = state.copyWith(
      languageName: newName,
      languageId: newId,
      languageAssetPath: newAsset,
      isLoading: true,
    );

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('usuarios')
            .update({'lenguaje_favorito': newId})
            .eq('id', user.id);
      } catch (e) {
        debugPrint("Error update language: $e");
      }
    }

    await fetchStatsForLanguage(newId);
  }

  void updateStatsDirectly({
    required int lives,
    required int trophies,
    required int streak,
  }) {
    state = state.copyWith(lives: lives, trophies: trophies, streak: streak);
  }
}

final appBarProvider =
    StateNotifierProvider.autoDispose<AppBarNotifier, AppBarState>((ref) {
      ref.watch(authStateProvider);
      return AppBarNotifier(Supabase.instance.client);
    });

final currentLanguageIdProvider = Provider<int>((ref) {
  return ref.watch(appBarProvider.select((state) => state.languageId));
});

final appBarRealtimeProvider = Provider.autoDispose((ref) {
  ref.watch(authStateProvider);

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  void refresh() {
    if (ref.read(shouldRefreshStatsProvider) == false) {
      ref.read(appBarProvider.notifier).fetchStats();
    }
  }

  final channels = [
    supabase
        .channel('public:estadistica_usuario:appbar:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'estadistica_usuario',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_usuario',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe(),
    supabase
        .channel('public:intento_reto:appbar:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'intento_reto',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_usuario',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe(),
    supabase
        .channel('public:usuarios:appbar:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'usuarios',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe(),
  ];

  ref.onDispose(() {
    for (var channel in channels) {
      supabase.removeChannel(channel);
    }
  });
});

final languageListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  return await supabase.from('lenguaje').select('id_lenguaje, nombre');
});
