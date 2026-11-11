import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_state.dart';
import 'data/database.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final name in [
      'Mihon-Apache-2.0',
      'TachiyomiX-Apache-2.0',
      'Keiyoushi-Apache-2.0',
      'QuickJS-Licenses',
      'Manrope-OFL',
      'Newsreader-OFL',
    ]) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString('assets/licenses/$name.txt'));
    }
  });
  try {
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(DreamDatabase(), preferences);
    await state.initialize();
    runApp(DreamReader(state: state));
  } catch (error) {
    runApp(
      MaterialApp(
        theme: dreamTheme(Appearance.dreamDark),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Dream Reader could not open its library.\n\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DreamReader extends StatelessWidget {
  final AppState state;
  const DreamReader({super.key, required this.state});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (_, child) => MaterialApp(
      title: 'Dream Reader',
      debugShowCheckedModeBanner: false,
      theme: dreamTheme(
        state.appearance,
        seed: state.accent,
        font: state.interfaceFont,
        density: state.interfaceDensity.toDouble(),
      ),
      home: state.onboardingDone ? DreamShell(state) : WelcomeScreen(state),
    ),
  );
}
