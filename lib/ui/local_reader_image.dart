import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../platform/engine.dart';

/// Tall Android pages are decoded in bounded native regions. Only visible
/// regions and one neighbour on each side remain mounted and cached.
class LocalReaderImage extends StatefulWidget {
  final String path;
  final SourceEngine engine;
  final bool fit;
  final VoidCallback onDecoded;
  final Widget Function(Object) errorBuilder;
  const LocalReaderImage({
    super.key,
    required this.path,
    required this.engine,
    required this.onDecoded,
    required this.errorBuilder,
    this.fit = false,
  });
  @override
  State<LocalReaderImage> createState() => _LocalReaderImageState();
}

class _LocalReaderImageState extends State<LocalReaderImage> {
  late Future<Json?> info = _info();
  Future<Json?> _info() async {
    if (widget.fit ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    return Map<String, dynamic>.from(
      await widget.engine.call('readerImageInfo', {'path': widget.path}),
    );
  }

  @override
  void didUpdateWidget(LocalReaderImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.fit != widget.fit) {
      info = _info();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json?>(
    future: info,
    builder: (_, snapshot) {
      if (snapshot.hasError) return widget.errorBuilder(snapshot.error!);
      if (snapshot.connectionState != ConnectionState.done) {
        return const ReaderImageLoading();
      }
      if (snapshot.data?['tiled'] == true) {
        return _RegionStrip(
          key: ValueKey(widget.path),
          path: widget.path,
          info: snapshot.data!,
          engine: widget.engine,
          onDecoded: widget.onDecoded,
          errorBuilder: widget.errorBuilder,
        );
      }
      return Image(
        image: ResizeImage(
          FileImage(File(widget.path)),
          width: 1800,
          height: 8192,
          policy: ResizeImagePolicy.fit,
        ),
        fit: widget.fit ? BoxFit.contain : BoxFit.fitWidth,
        width: double.infinity,
        frameBuilder: (_, child, frame, _) {
          if (frame == null) return const ReaderImageLoading();
          widget.onDecoded();
          return child;
        },
        errorBuilder: (_, error, _) => widget.errorBuilder(error),
      );
    },
  );
}

class ReaderImageLoading extends StatelessWidget {
  const ReaderImageLoading({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 260,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _RegionStrip extends StatefulWidget {
  final String path;
  final Json info;
  final SourceEngine engine;
  final VoidCallback onDecoded;
  final Widget Function(Object) errorBuilder;
  const _RegionStrip({
    super.key,
    required this.path,
    required this.info,
    required this.engine,
    required this.onDecoded,
    required this.errorBuilder,
  });
  @override
  State<_RegionStrip> createState() => _RegionStripState();
}

class _RegionStripState extends State<_RegionStrip> {
  ScrollPosition? position;
  int first = 0, last = 1;
  double regionExtent = 1;
  bool scheduled = false;
  int get count => widget.info['count'] as int;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (position != next) {
      position?.removeListener(_schedule);
      position = next;
      position?.addListener(_schedule);
    }
    _schedule();
  }

  void _schedule() {
    if (scheduled) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || regionExtent <= 0) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final viewport = MediaQuery.sizeOf(context).height;
      final start = ((-top / regionExtent).floor() - 1).clamp(0, count - 1);
      final end = (((viewport - top) / regionExtent).ceil() + 1).clamp(
        0,
        count - 1,
      );
      if (first != start || last != end) {
        setState(() {
          first = start;
          last = end;
        });
      }
    });
  }

  @override
  void dispose() {
    position?.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final scale = constraints.maxWidth / (widget.info['width'] as int);
      regionExtent = (widget.info['regionHeight'] as int) * scale;
      final height = (widget.info['height'] as int) * scale;
      _schedule();
      return SizedBox(
        height: height,
        width: constraints.maxWidth,
        child: Stack(
          children: [
            for (var index = first; index <= last && index < count; index++)
              Positioned(
                key: ValueKey(index),
                top: index * regionExtent,
                left: 0,
                right: 0,
                height: (height - index * regionExtent).clamp(0, regionExtent),
                child: _ImageRegion(
                  path: widget.path,
                  index: index,
                  engine: widget.engine,
                  onDecoded: index == count - 1 ? widget.onDecoded : () {},
                  errorBuilder: widget.errorBuilder,
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ImageRegion extends StatefulWidget {
  final String path;
  final int index;
  final SourceEngine engine;
  final VoidCallback onDecoded;
  final Widget Function(Object) errorBuilder;
  const _ImageRegion({
    required this.path,
    required this.index,
    required this.engine,
    required this.onDecoded,
    required this.errorBuilder,
  });
  @override
  State<_ImageRegion> createState() => _ImageRegionState();
}

class _ImageRegionState extends State<_ImageRegion> {
  static int nextRequest = 0;
  final requestId = ++nextRequest;
  MemoryImage? provider;
  late Future<MemoryImage> image = _load();
  Future<MemoryImage> _load() async {
    final bytes = await widget.engine.call('readerImageRegion', {
      'path': widget.path,
      'index': widget.index,
      'requestId': requestId,
    }) as Uint8List;
    final result = MemoryImage(bytes);
    if (mounted) provider = result;
    return result;
  }

  @override
  void dispose() {
    // ImageCache otherwise retains every strip visited in a long chapter.
    provider?.evict();
    // Drop queued native decoding when this region scrolls out of the viewport.
    unawaited(
      widget.engine
          .call('readerCancelRegion', {'requestId': requestId})
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MemoryImage>(
    future: image,
    builder: (_, snapshot) {
      if (snapshot.hasError) {
        return SingleChildScrollView(
          child: widget.errorBuilder(snapshot.error!),
        );
      }
      if (!snapshot.hasData) return const ReaderImageLoading();
      return Image(
        image: snapshot.data!,
        fit: BoxFit.fill,
        gaplessPlayback: false,
        frameBuilder: (_, child, frame, _) {
          if (frame == null) return const ReaderImageLoading();
          widget.onDecoded();
          return child;
        },
        errorBuilder: (_, error, _) => widget.errorBuilder(error),
      );
    },
  );
}
