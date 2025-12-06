import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:kitsucode/shared/elastic_list_view/custom_scroll_behavior.dart';
import 'package:kitsucode/shared/elastic_list_view/elastic_list_view.dart';

class ElasticListView extends StatefulWidget {
  final Axis scrollDirection;

  final bool reverse;

  final ScrollController? controller;

  final bool? primary;

  final ScrollPhysics? physics;

  final bool shrinkWrap;

  final EdgeInsetsGeometry? padding;

  final double? itemExtent;

  final ItemExtentBuilder? itemExtentBuilder;

  final Widget? prototypeItem;

  final IndexedWidgetBuilder itemBuilder;

  final ChildIndexGetter? findChildIndexCallback;

  final int? itemCount;

  final bool addAutomaticKeepAlives;

  final bool addRepaintBoundaries;

  final bool addSemanticIndexes;

  final double? cacheExtent;

  final int? semanticChildCount;

  final DragStartBehavior dragStartBehavior;

  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  final String? restorationId;

  final Clip clipBehavior;

  final Curve curve;

  final Duration animationDuration;

  final bool enableDragScrolling;

  final int elasticityFactor;

  final IndexedWidgetBuilder? separatorBuilder;

  final List<Widget>? children;

  const ElasticListView._base({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.itemExtentBuilder,
    this.prototypeItem,
    required this.itemBuilder,
    this.children,
    this.findChildIndexCallback,
    required this.itemCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.curve = Curves.easeOut,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableDragScrolling = true,
    this.elasticityFactor = 4,
    this.separatorBuilder,
  }) : assert(
         elasticityFactor >= 0,
         'Elasticity factor must be greater than or equal to 0.',
       ),
       assert(
         animationDuration >= const Duration(milliseconds: 100),
         'Animation duration should be greater than or equal to 100 ms for optimal user experience.',
       );

  ElasticListView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    ItemExtentBuilder? itemExtentBuilder,
    Widget? prototypeItem,
    required List<Widget> children,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Curve curve = Curves.easeOut,
    Duration animationDuration = const Duration(milliseconds: 200),
    bool enableDragScrolling = true,
    int elasticityFactor = 4,
  }) : this._base(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
         itemExtent: itemExtent,
         itemExtentBuilder: itemExtentBuilder,
         prototypeItem: prototypeItem,
         itemBuilder: (_, int index) => children[index],
         findChildIndexCallback: findChildIndexCallback,
         itemCount: children.length,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
         cacheExtent: cacheExtent,
         semanticChildCount: semanticChildCount,
         dragStartBehavior: dragStartBehavior,
         keyboardDismissBehavior: keyboardDismissBehavior,
         restorationId: restorationId,
         clipBehavior: clipBehavior,
         curve: curve,
         animationDuration: animationDuration,
         enableDragScrolling: enableDragScrolling,
         elasticityFactor: elasticityFactor,
       );

  const ElasticListView.builder({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    ItemExtentBuilder? itemExtentBuilder,
    Widget? prototypeItem,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Curve curve = Curves.easeOut,
    Duration animationDuration = const Duration(milliseconds: 200),
    bool enableDragScrolling = true,
    int elasticityFactor = 4,
  }) : this._base(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
         itemExtent: itemExtent,
         itemExtentBuilder: itemExtentBuilder,
         prototypeItem: prototypeItem,
         itemBuilder: itemBuilder,
         findChildIndexCallback: findChildIndexCallback,
         itemCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
         cacheExtent: cacheExtent,
         semanticChildCount: semanticChildCount,
         dragStartBehavior: dragStartBehavior,
         keyboardDismissBehavior: keyboardDismissBehavior,
         restorationId: restorationId,
         clipBehavior: clipBehavior,
         curve: curve,
         animationDuration: animationDuration,
         enableDragScrolling: enableDragScrolling,
         elasticityFactor: elasticityFactor,
       );

  const ElasticListView.separated({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    ItemExtentBuilder? itemExtentBuilder,
    Widget? prototypeItem,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Curve curve = Curves.easeOut,
    Duration animationDuration = const Duration(milliseconds: 200),
    bool enableDragScrolling = true,
    int elasticityFactor = 4,
    required IndexedWidgetBuilder separatorBuilder,
  }) : this._base(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
         itemExtent: itemExtent,
         itemExtentBuilder: itemExtentBuilder,
         prototypeItem: prototypeItem,
         itemBuilder: itemBuilder,
         findChildIndexCallback: findChildIndexCallback,
         itemCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
         cacheExtent: cacheExtent,
         semanticChildCount: semanticChildCount,
         dragStartBehavior: dragStartBehavior,
         keyboardDismissBehavior: keyboardDismissBehavior,
         restorationId: restorationId,
         clipBehavior: clipBehavior,
         curve: curve,
         animationDuration: animationDuration,
         enableDragScrolling: enableDragScrolling,
         elasticityFactor: elasticityFactor,
         separatorBuilder: separatorBuilder,
       );

  @override
  ElasticListViewState createState() => ElasticListViewState();
}

class ElasticListViewState extends State<ElasticListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late ScrollController _scrollController;

  double _elasticity = 1.0;

  double _previousOffset = 0.0;

  DateTime _previousTimestamp = DateTime.now();

  double get elasticity => _elasticity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  EdgeInsets get _padding => widget.scrollDirection == Axis.vertical
      ? EdgeInsets.symmetric(
          vertical: (elasticity - 1) * widget.elasticityFactor,
        )
      : EdgeInsets.symmetric(
          horizontal: (elasticity - 1) * widget.elasticityFactor,
        );

  ScrollBehavior get _scrollBehavior => widget.enableDragScrolling
      ? DragScrollBehavior()
      : const ScrollBehavior();
  @override
  Widget build(BuildContext context) {
    final listView = widget.separatorBuilder != null
        ? ListView.separated(
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            controller: _scrollController,
            primary: widget.primary,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            padding: widget.padding,
            itemCount: widget.itemCount!,
            itemBuilder: _itemBuilder,
            separatorBuilder: _separatorBuilder,
            addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
            addRepaintBoundaries: widget.addRepaintBoundaries,
            addSemanticIndexes: widget.addSemanticIndexes,
            cacheExtent: widget.cacheExtent,
            dragStartBehavior: widget.dragStartBehavior,
            keyboardDismissBehavior: widget.keyboardDismissBehavior,
            restorationId: widget.restorationId,
            clipBehavior: widget.clipBehavior,
          )
        : ListView.builder(
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            controller: _scrollController,
            primary: widget.primary,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            padding: widget.padding,
            itemExtent: widget.itemExtent,
            itemCount: widget.itemCount,
            itemBuilder: _itemBuilder,
            addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
            addRepaintBoundaries: widget.addRepaintBoundaries,
            addSemanticIndexes: widget.addSemanticIndexes,
            cacheExtent: widget.cacheExtent,
            semanticChildCount: widget.semanticChildCount,
            dragStartBehavior: widget.dragStartBehavior,
            keyboardDismissBehavior: widget.keyboardDismissBehavior,
            restorationId: widget.restorationId,
            clipBehavior: widget.clipBehavior,
          );

    return ScrollConfiguration(
      behavior: _scrollBehavior,
      child: NotificationListener<UserScrollNotification>(
        onNotification: _notificationHandler,
        child: listView,
      ),
    );
  }

  Widget _separatorBuilder(BuildContext context, int index) =>
      _itemBuilder(context, index, true);

  Widget _itemBuilder(
    BuildContext context,
    int index, [
    bool isSeparator = false,
  ]) {
    final child = isSeparator
        ? widget.separatorBuilder!(context, index)
        : widget.itemBuilder(context, index);

    return AnimatedPadding(
      duration: widget.animationDuration,
      curve: widget.curve,
      padding: _padding,
      child: child,
    );
  }

  void _handleScroll() {
    if (!_scrollController.position.outOfRange &&
        (_scrollController.offset >=
                _scrollController.position.maxScrollExtent ||
            _scrollController.offset <=
                _scrollController.position.minScrollExtent)) {
      _resetElasticity();
    } else {
      final overscroll = ElasticListViewUtils.calculateOverscroll(
        _scrollController,
      );
      final simulation = ElasticListViewUtils.calculateSimulation(overscroll);

      _controller.animateWith(simulation);

      _updateElasticity();
    }
  }

  bool _notificationHandler(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.idle &&
        _scrollController.position.isScrollingNotifier is! IdleScrollActivity) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _resetElasticity());
    }

    return false;
  }

  void _resetElasticity() {
    setState(() {
      _controller.value = 0.0;

      _elasticity = 1.0;
    });
  }

  void _updateElasticity() {
    final DateTime now = DateTime.now();

    final Duration timeDelta = now.difference(_previousTimestamp);

    if (timeDelta.inMilliseconds != 0) {
      final double scrollSpeed = ElasticListViewUtils.calculateScrollSpeed(
        _scrollController,
        _previousOffset,
        _previousTimestamp,
      );

      _previousOffset = _scrollController.offset;
      _previousTimestamp = now;

      _elasticity = ElasticListViewUtils.calculateElasticity(
        _controller,
        scrollSpeed,
      );

      setState(() {});
    }
  }
}
