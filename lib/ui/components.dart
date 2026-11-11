import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../domain/models.dart';
import 'theme.dart';

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeading(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(color: dreamMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class CoverImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final Map<String, String>? headers;
  const CoverImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.headers,
  });
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      child: const Center(
        child: Icon(Icons.auto_stories_outlined, color: dreamMuted, size: 30),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: url.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: url,
              httpHeaders: headers,
              width: width,
              height: height,
              fit: BoxFit.cover,
              memCacheWidth: 500,
              placeholder: (_, url) => fallback,
              errorWidget: (_, url, error) => fallback,
            ),
    );
  }
}

class MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  const MangaCard(
    this.manga, {
    super.key,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: manga.title,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverImage(manga.cover),
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      color: dreamMint.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: dreamMint,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .08),
              ),
              child: Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Newsreader', fontSize: 29),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: dreamMuted,
              ),
            ),
            if (action != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: FilledButton(onPressed: onAction, child: Text(action!)),
              ),
          ],
        ),
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  final Object error;
  final VoidCallback? retry;
  const ErrorNotice(this.error, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'A pause in the story',
    message: error.toString().replaceFirst('Exception: ', ''),
    action: retry == null ? null : 'Try again',
    onAction: retry,
  );
}
