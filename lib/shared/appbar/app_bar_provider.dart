import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';

const String _defaultAsset = 'assets/images/home/logo_python.webp';

// 1. EL MODELO DEL ESTADO
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

// 2. EL NOTIFIER (LÓGICA)
class AppBarNotifier extends StateNotifier<AppBarState> {
  final SupabaseClient _supabase;

  AppBarNotifier(this._supabase)
    : super(const AppBarState(isLoading: true, languageAssetPath: _defaultAsset)) {
    fetchStats();
  }

  String _getAssetForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python': return 'assets/images/home/logo_python.webp';
      case 'java': return 'assets/images/home/logo_java.webp';
      case 'c': return 'assets/images/home/logo_c.webp';
      default: return _defaultAsset;
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
          lives: 0, streak: 0, trophies: 0,
        );
        return;
      }

      // 1. Obtener ID de lenguaje favorito
      final userData = await _supabase
          .from('usuarios')
          .select('lenguaje_favorito')
          .eq('id', user.id)
          .maybeSingle();

      final langId = (userData?['lenguaje_favorito'] ?? 1) as int;

      // 2. Carga Paralela: Trofeos (RPC), Stats y Nombre Lenguaje
      final responses = await Future.wait<dynamic>([
        _supabase.rpc('get_my_language_score', params: {'p_language_id': langId}),
        _supabase.from('estadistica_usuario').select('racha_dias, vidas').eq('id_usuario', user.id).maybeSingle(),
        _supabase.from('lenguaje').select('nombre').eq('id_lenguaje', langId).single(),
      ]);

      // 3. Procesamiento Seguro de Datos
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

  // Cambiar lenguaje (Optimista + BD + Fetch)
  Future<void> updateLanguage(String newName, int newId) async {
    final newAsset = _getAssetForLanguage(newName);
    
    // Update visual inmediato
    state = state.copyWith(
      languageName: newName,
      languageId: newId,
      languageAssetPath: newAsset,
      trophies: 0, 
      isLoading: true,
    );

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('usuarios').update({'lenguaje_favorito': newId}).eq('id', user.id);
      } catch (e) {
        debugPrint("Error update language: $e");
      }
    }
    await fetchStats();
  }

  // Método para el "Truco del Rebobinado"
  void updateStatsDirectly({required int lives, required int trophies, required int streak}) {
    state = state.copyWith(lives: lives, trophies: trophies, streak: streak);
  }
}

// 3. PROVIDERS
final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarState>((ref) {
  return AppBarNotifier(Supabase.instance.client);
});

final currentLanguageIdProvider = Provider<int>((ref) {
  return ref.watch(appBarProvider.select((state) => state.languageId));
});

// Provider Realtime (Optimizado)
final appBarRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  void refresh() {
    // Solo refrescamos si NO estamos en una pantalla que lo prohíba (ej. juego/feedback)
    if (!ref.read(shouldRefreshStatsProvider)) {
      ref.read(appBarProvider.notifier).fetchStats();
    }
  }

  final channels = [
    supabase.channel('public:estadistica_usuario:appbar')
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'estadistica_usuario', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id_usuario', value: userId), callback: (_) => refresh())
      .subscribe(),
    supabase.channel('public:intento_reto:appbar')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'intento_reto', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id_usuario', value: userId), callback: (_) => refresh())
      .subscribe(),
    supabase.channel('public:usuarios:appbar')
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'usuarios', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: userId), callback: (_) => ref.read(appBarProvider.notifier).fetchStats())
      .subscribe(),
  ];

  ref.onDispose(() {
    for (var channel in channels) {
      supabase.removeChannel(channel);
    }
  });
});

final languageListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  return await supabase.from('lenguaje').select('id_lenguaje, nombre');
});