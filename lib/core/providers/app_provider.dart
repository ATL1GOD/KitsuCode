import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationReturnPathProvider = StateProvider<String>((ref) {
  return '/home';
});
