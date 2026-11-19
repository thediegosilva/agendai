import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  // As fontes vêm embutidas no app (assets/google_fonts): abre mais rápido
  // e funciona sem internet.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: AgendaiApp()));
}

class AgendaiApp extends ConsumerWidget {
  const AgendaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AgendaÍ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
