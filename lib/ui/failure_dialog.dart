import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/failure_message.dart';

class FailureDialog extends StatelessWidget {
  final String title;
  final Object error;
  const FailureDialog({super.key, required this.title, required this.error});
  @override
  Widget build(BuildContext context) {
    final failure = FailureMessage.from(error);
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(failure.message),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Technical details',
                style: TextStyle(fontSize: 13),
              ),
              children: [
                SelectableText(
                  failure.details,
                  style: const TextStyle(fontSize: 12),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy details'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: failure.details),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Details copied')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
