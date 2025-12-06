import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class ElasticListViewUtils {
  static const double minElasticity = 1.0;

  static const double maxElasticity = 3.0;

  static const double scrollSpeedFactor = 1.2;

  static const double controllerValueFactor = 0.2;

  static double calculateOverscroll(ScrollController scrollController) {
    final currentOffset = scrollController.offset;
    return currentOffset < 0.0
        ? currentOffset
        : currentOffset - scrollController.position.maxScrollExtent;
  }

  static double calculateScrollSpeed(
    ScrollController scrollController,
    double previousOffset,
    DateTime previousTimestamp,
  ) {
    final now = DateTime.now();
    final timeDelta = now.difference(previousTimestamp).inMilliseconds;
    final scrollSpeed = (scrollController.offset - previousOffset) / timeDelta;
    return scrollSpeed;
  }

  static SpringSimulation calculateSimulation(double overscroll) {
    return SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 300.0, damping: 20.0),
      0.0,
      overscroll,
      0.0,
    );
  }

  static double calculateElasticity(
    AnimationController controller,
    double scrollSpeed,
  ) {
    return (minElasticity +
            controller.value * controllerValueFactor +
            scrollSpeed.abs() * scrollSpeedFactor)
        .clamp(minElasticity, maxElasticity);
  }
}
