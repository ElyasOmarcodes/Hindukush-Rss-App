import 'package:flutter/material.dart';

/// A large app bar whose title is **one** widget that shrinks and travels up
/// into the toolbar as the page scrolls.
///
/// [SliverAppBar.large] builds *two* titles — a big one in the flexible space
/// and a separate small one in the toolbar — and cross-fades between them, so
/// partway through the scroll the large title fades out and a different, small
/// title fades in. [FlexibleSpaceBar] instead interpolates a single title's
/// scale and position, so the same text travels the whole distance and its size
/// tracks the scroll offset continuously.
class ExpressiveSliverAppBar extends StatelessWidget {
  const ExpressiveSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.expandedHeight = 148,
    this.expandedTitleScale = 1.45,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double expandedHeight;

  /// How much bigger the title is when fully expanded. The base style is the
  /// app bar's titleLarge (22sp), so 1.45 lands around 32sp expanded.
  final double expandedTitleScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasLeading = leading != null ||
        (automaticallyImplyLeading && Navigator.of(context).canPop());

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        expandedTitleScale: expandedTitleScale,
        // The title anchors where it will finally sit in the toolbar, clearing
        // the back button when there is one.
        titlePadding: EdgeInsetsDirectional.only(
          start: hasLeading ? 72 : 20,
          end: 20,
          bottom: 16,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
