import 'package:flutter/material.dart';

import '../domain/models.dart';

/// Renders the extension's current filter schema; identifiers are native index paths.
class SourceFiltersSheet extends StatefulWidget {
  final List<Json> schema;
  final Json selected;
  const SourceFiltersSheet(this.schema, this.selected, {super.key});
  @override
  State<SourceFiltersSheet> createState() => _SourceFiltersSheetState();
}

class _SourceFiltersSheetState extends State<SourceFiltersSheet> {
  late final Json values = Map.of(widget.selected);
  dynamic value(Json field) =>
      values.containsKey(field['id']) ? values[field['id']] : field['value'];
  Widget field(Json field) {
    final id = field['id'] as String, name = field['name'] as String;
    switch (field['type']) {
      case 'header':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(name, style: Theme.of(context).textTheme.titleMedium),
        );
      case 'separator':
        return const Divider();
      case 'group':
        return ExpansionTile(
          title: Text(name),
          children: [
            for (final child in field['children'])
              this.field(Map<String, dynamic>.from(child)),
          ],
        );
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextFormField(
            initialValue: value(field) as String?,
            maxLength: 4096,
            decoration: InputDecoration(labelText: name, counterText: ''),
            onChanged: (v) => values[id] = v,
          ),
        );
      case 'check':
        return CheckboxListTile(
          title: Text(name),
          value: value(field) == true,
          onChanged: (v) => setState(() => values[id] = v),
        );
      case 'tri':
        return ListTile(
          title: Text(name),
          trailing: DropdownButton<int>(
            value: value(field) as int? ?? 0,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Any')),
              DropdownMenuItem(value: 1, child: Text('Include')),
              DropdownMenuItem(value: 2, child: Text('Exclude')),
            ],
            onChanged: (v) => setState(() => values[id] = v),
          ),
        );
      case 'select':
        final options = List<String>.from(field['values']);
        if (options.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<int>(
            initialValue: (value(field) as int? ?? 0).clamp(
              0,
              options.length - 1,
            ),
            isExpanded: true,
            decoration: InputDecoration(labelText: name),
            items: [
              for (var i = 0; i < options.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    options[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => values[id] = v),
          ),
        );
      case 'sort':
        final options = List<String>.from(field['values']);
        final current = value(field) as Map?;
        return Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: current?['index'] as int?,
              isExpanded: true,
              decoration: InputDecoration(labelText: name),
              items: [
                for (var i = 0; i < options.length; i++)
                  DropdownMenuItem(value: i, child: Text(options[i])),
              ],
              onChanged: (v) => setState(
                () => values[id] = {
                  'index': v,
                  'ascending': current?['ascending'] ?? false,
                },
              ),
            ),
            if (current != null)
              SwitchListTile(
                title: const Text('Ascending'),
                value: current['ascending'] == true,
                onChanged: (v) => setState(
                  () =>
                      values[id] = {'index': current['index'], 'ascending': v},
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Refine your discovery',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, <String, dynamic>{}),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(children: widget.schema.map(field).toList()),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, values),
              child: const Text('Show results'),
            ),
          ),
        ],
      ),
    ),
  );
}
