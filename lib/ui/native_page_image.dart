import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../platform/engine.dart';

class NativePageImage extends StatefulWidget {
  final ReaderPage page;
  final SourceEngine engine;
  final bool fit;
  final VoidCallback? onDecoded;
  const NativePageImage(
    this.page,
    this.engine, {
    super.key,
    this.fit = false,
    this.onDecoded,
  });
  @override
  State<NativePageImage> createState() => _NativePageImageState();
}

class _NativePageImageState extends State<NativePageImage> {
  late Future<String> path = load();
  Future<String> load() async {
    final result = await widget.engine.call('image', {
      'sourceId': widget.page.sourceId,
      'page': widget.page.toJson(),
    });
    return result['path'] as String;
  }

  @override
  void didUpdateWidget(NativePageImage old) {
    super.didUpdateWidget(old);
    if (old.page.url != widget.page.url ||
        old.page.sourceId != widget.page.sourceId) {
      path = load();
    }
  }

  Widget failure(Object error) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_outlined, color: Colors.white54),
        const SizedBox(height: 12),
        Text(
          'Page ${widget.page.index + 1} could not load.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        TextButton(
          onPressed: () => setState(() => path = load()),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: path,
    builder: (_, snapshot) {
      if (snapshot.hasError) return failure(snapshot.error!);
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 260,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return Image(
        image: ResizeImage(
          FileImage(File(snapshot.data!)),
          width: 1800,
          height: 8192,
          policy: ResizeImagePolicy.fit,
        ),
        fit: widget.fit ? BoxFit.contain : BoxFit.fitWidth,
        width: double.infinity,
        frameBuilder: (_, child, frame, _) {
          if (frame != null) widget.onDecoded?.call();
          return child;
        },
        errorBuilder: (_, error, _) => failure(error),
      );
    },
  );
}
