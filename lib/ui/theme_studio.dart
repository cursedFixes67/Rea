import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'theme.dart';

class ThemeStudioScreen extends StatefulWidget {
  final AppState state;
  const ThemeStudioScreen(this.state, {super.key});
  @override
  State<ThemeStudioScreen> createState() => _ThemeStudioScreenState();
}

class _ThemeStudioScreenState extends State<ThemeStudioScreen> {
  final form = GlobalKey<FormState>();
  late Color accent = widget.state.accent;
  late String font = widget.state.interfaceFont;
  late int density = widget.state.interfaceDensity;
  late final hex = TextEditingController(text: _hex(accent));
  bool saving = false;
  String _hex(Color color) => color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2)
      .toUpperCase();
  Color? _parse(String? value) {
    final clean = (value ?? '').trim().replaceFirst('#', '');
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)
        ? Color(0xff000000 | int.parse(clean, radix: 16))
        : null;
  }

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.state.setAccent(_parse(hex.text)!);
      await widget.state.setTypography(font, density);
      await widget.state.setAppearance(Appearance.custom);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save appearance: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Theme Studio')),
    body: Form(
      key: form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Make it yours.',
              style: TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 38,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Color, type and breathing room. Preview your changes before applying them.',
              style: TextStyle(color: mutedColor(context), height: 1.6),
            ),
            const SizedBox(height: 28),
            Theme(
              data: dreamTheme(
                Appearance.custom,
                seed: accent,
                font: font,
                density: density.toDouble(),
              ),
              child: Builder(
                builder: (context) {
                  final colors = Theme.of(context).colorScheme;
                  return Material(
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: .35),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DreamMark(size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'DREAM READER',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'A chapter of your own',
                            style: TextStyle(
                              fontFamily: 'Newsreader',
                              fontSize: 28,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your stories, in a space that feels like you.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                color: colors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Reading room',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: colors.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Accent palette',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  {
                        'Jade': dreamMint,
                        'Apricot': const Color(0xFFFFC48C),
                        'Wisteria': const Color(0xFFCBB5FD),
                        'Glacier': const Color(0xFF8ED0F4),
                        'Rose': const Color(0xFFF4A8BD),
                      }.entries
                      .map(
                        (entry) => Semantics(
                          selected: accent == entry.value,
                          child: IconButton.filled(
                            tooltip: entry.key,
                            style: IconButton.styleFrom(
                              backgroundColor: entry.value,
                              foregroundColor: Colors.black87,
                            ),
                            onPressed: () => setState(() {
                              accent = entry.value;
                              hex.text = _hex(accent);
                            }),
                            icon: Icon(
                              accent == entry.value
                                  ? Icons.check
                                  : Icons.circle,
                              size: accent == entry.value ? 24 : 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: hex,
              decoration: const InputDecoration(
                labelText: 'Custom color',
                prefixText: '#',
                hintText: 'A8E6CF',
                helperText: 'Readable shades are generated from your color.',
              ),
              maxLength: 7,
              autocorrect: false,
              validator: (value) => _parse(value) == null
                  ? 'Enter a six-digit hex color, such as A8E6CF.'
                  : null,
              onChanged: (value) {
                final parsed = _parse(value);
                if (parsed != null) setState(() => accent = parsed);
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: font,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Interface typography',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Manrope',
                  child: Text('Manrope · modern sans'),
                ),
                DropdownMenuItem(
                  value: 'Newsreader',
                  child: Text('Newsreader · literary serif'),
                ),
                DropdownMenuItem(value: 'system', child: Text('System font')),
              ],
              onChanged: (value) => setState(() => font = value!),
            ),
            const SizedBox(height: 24),
            const Text(
              'Interface spacing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: {-1: 'Compact', 0: 'Balanced', 1: 'Relaxed'}.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: density == entry.key,
                      onSelected: (_) => setState(() => density = entry.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? 'Saving…' : 'Apply appearance'),
            ),
          ],
        ),
      ),
    ),
  );
}
