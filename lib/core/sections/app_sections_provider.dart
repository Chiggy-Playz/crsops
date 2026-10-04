import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_section.dart';

part 'app_sections_provider.g.dart';

/// Every section, in nav order. Core can't build this list itself (that would
/// mean importing modules), so `main.dart` overrides it with `allSections`
/// from the composition root; tests override it with whatever they need.
@Riverpod(keepAlive: true)
List<AppSection> appSections(Ref ref) => throw UnimplementedError(
  'appSectionsProvider must be overridden in ProviderScope',
);
