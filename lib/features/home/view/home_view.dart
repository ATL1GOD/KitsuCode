import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/provider/home_provider.dart';
import 'package:kitsucode/features/home/view/widgets/map_home.dart';
import 'package:kitsucode/shared/appbar/kitsu_appbar.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/shared/appbar/navigation_tracker_provider.dart';
import 'package:kitsucode/main.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with RouteAware {
  int iCurrentSection = 0;

  final double _changeThresholdPosition = 102.0;
  final heightFirstBox = 192.0;

  final List<double> _sectionOffsets = [];
  final scrollCtrl = ScrollController();

  final double _anticipationMargin = 0.1;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSectionOffsets();
      scrollListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // Detectar cuando REGRESAS al Home
  @override
  void didPopNext() {
    // Delay para que la pantalla se estabilice
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      try {
        final audioController = ref.read(audioControllerProvider);
        final currentLang = ref.read(appBarProvider).languageName;
        
        if (currentLang.isNotEmpty) {
          audioController.playBackgroundMusic(currentLang);
        }
      } catch (e) {
        // Fallo silencioso
      }
    });
  }

  @override
  void didPushNext() {
  }

  void _calculateSectionOffsets() {
    final sectionsAsync = ref.read(homeViewModelProvider);

    sectionsAsync.whenData((sections) {
      if (sections.isEmpty) return;
      double currentOffset = heightFirstBox + 24.0;
      _sectionOffsets.clear();
      _sectionOffsets.add(currentOffset);
      for (int i = 0; i < sections.length; i++) {
        final section = sections[i];
        const double sectionHeaderHeight = 60.0;
        const double buttonHeight = 56.0 + 6.0;
        final double stackHeight = section.levels.isEmpty
            ? 0.0
            : ((section.levels.length - 1) * 96.0 + 40.0) + buttonHeight;
        double sectionWidgetHeight = sectionHeaderHeight + stackHeight;
        double totalSectionBlockHeight = sectionWidgetHeight + 100.0 + 24.0;
        currentOffset += totalSectionBlockHeight;
        _sectionOffsets.add(currentOffset);
      }
    });
  }

  void scrollListener() {
    if (_sectionOffsets.isEmpty) return;
    final currentScroll = scrollCtrl.position.pixels;

    final double titleDisplayPosition =
        currentScroll + _changeThresholdPosition - _anticipationMargin;

    int newIndex = 0;
    for (int i = _sectionOffsets.length - 1; i >= 0; i--) {
      if (titleDisplayPosition >= _sectionOffsets[i]) {
        newIndex = i;
        break;
      }
    }
    final sections = ref.read(homeViewModelProvider).value ?? [];
    newIndex = newIndex.clamp(0, sections.length - 1);
    if (newIndex != iCurrentSection) {
      setState(() => iCurrentSection = newIndex);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    scrollCtrl.removeListener(scrollListener);
    scrollCtrl.dispose();
    super.dispose();
  }

  String _getMapBackgroundForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return 'assets/images/home/camino_python.webp';
      case 'java':
        return 'assets/images/home/camino_java.webp';
      case 'c':
        return 'assets/images/home/camino_c.webp';
      default:
        return 'assets/images/home/camino_python.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mapStructureRealtimeProvider);
    ref.read(progressRealtimeProvider);

    final shouldRefresh = ref.watch(shouldRefreshStatsProvider);

    if (shouldRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final currentRoute = GoRouterState.of(context).uri.toString();

        if (currentRoute != '/home') {
          return;
        }

        final oldValues = ref.read(oldStatsValuesProvider);

        if (oldValues != null && oldValues.length == 3) {
          ref
              .read(appBarProvider.notifier)
              .updateStatsDirectly(
                lives: oldValues[0],
                trophies: oldValues[1],
                streak: oldValues[2],
              );
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
          if (!mounted) return;
          await ref.read(appBarProvider.notifier).fetchStats();
          ref.read(shouldRefreshStatsProvider.notifier).state = false;
        }
      });
    }

    final sectionsAsync = ref.watch(homeViewModelProvider);
    final appBarState = ref.read(appBarProvider);
    final mapAssetPath = _getMapBackgroundForLanguage(appBarState.languageName);

    return Scaffold(
      body: sectionsAsync.when(
        data: (sections) {
          if (sections.isNotEmpty &&
              (_sectionOffsets.isEmpty ||
                  _sectionOffsets.length != sections.length + 1)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _calculateSectionOffsets(),
            );
          }

          if (sections.isEmpty) {
            final isAppBarLoading = ref.read(appBarProvider).isLoading;
            if (isAppBarLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(
              child: Text("No hay secciones para este lenguaje."),
            );
          }

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(mapAssetPath),
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.noRepeat,
                  ),
                ),
              ),

              ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
                itemBuilder: (_, i) => i == 0
                    ? SizedBox(height: heightFirstBox)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Section(data: sections[i - 1]),
                          const SizedBox(height: 100.0),
                        ],
                      ),
                separatorBuilder: (_, i) => const SizedBox(height: 24.0),
                itemCount: sections.length + 1,
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _changeThresholdPosition,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(mapAssetPath),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  child: ClipRRect(),
                ),
              ),

              const Positioned(top: 0, left: 0, right: 0, child: KitsuAppBar()),

              Positioned(
                top: _changeThresholdPosition,
                left: 0,
                right: 0,
                child: CurrentSection(
                  data: sections[iCurrentSection.clamp(0, sections.length - 1)],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error al cargar: $err")),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

class CurrentSection extends StatelessWidget {
  final SectionData data;

  const CurrentSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(16.0),
        border: Border(bottom: BorderSide(color: data.colorOscuro, width: 4.0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ETAPA ${data.etapa}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  data.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: data.colorOscuro, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}