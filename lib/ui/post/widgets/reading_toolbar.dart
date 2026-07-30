import 'package:flutter/material.dart';

/// The floating bottom toolbar in the post view (image5): a soft rounded pill
/// of quick actions.
class ReadingToolbar extends StatelessWidget {
  const ReadingToolbar({
    super.key,
    required this.isFavorite,
    required this.onCopy,
    required this.onShare,
    required this.onToggleFavorite,
    required this.onQuickSettings,
    required this.onOpenWebsite,
  });

  final bool isFavorite;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final VoidCallback onQuickSettings;
  final VoidCallback onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(context, Icons.copy_rounded, onCopy),
            _btn(context, Icons.share_rounded, onShare),
            _btn(
              context,
              isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              onToggleFavorite,
              highlight: isFavorite,
            ),
            _btn(context, Icons.open_in_new_rounded, onOpenWebsite),
            _btn(context, Icons.tune_rounded, onQuickSettings),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, VoidCallback onTap,
      {bool highlight = false}) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      isSelected: highlight,
      style: IconButton.styleFrom(
        backgroundColor: highlight ? scheme.primary : Colors.transparent,
        foregroundColor:
            highlight ? scheme.onPrimary : scheme.onSecondaryContainer,
      ),
      icon: Icon(icon),
    );
  }
}
