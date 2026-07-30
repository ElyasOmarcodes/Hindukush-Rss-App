import 'package:flutter/material.dart';

import '../../../core/config/feeds.dart';
import '../../navigation/routes.dart';
import 'category_card.dart';

/// The Home sections list: each top-level section is a card; sections with
/// sub-items keep them collapsed behind an expander that reveals them with a
/// smooth transition.
class SectionList extends StatelessWidget {
  const SectionList({super.key, required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < kSections.length; i++) {
      final section = kSections[i];
      if (!section.availableFor(lang)) continue;
      tiles.add(SectionTile(section: section, lang: lang, colorIndex: i));
    }
    return Column(children: tiles);
  }
}

class SectionTile extends StatefulWidget {
  const SectionTile({
    super.key,
    required this.section,
    required this.lang,
    required this.colorIndex,
  });

  final FeedCategory section;
  final AppLanguage lang;
  final int colorIndex;

  @override
  State<SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<SectionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final children =
        widget.section.children.where((c) => c.availableFor(lang)).toList();
    final hasChildren = children.isNotEmpty;

    return Column(
      children: [
        CategoryCard(
          category: widget.section,
          lang: lang,
          colorIndex: widget.colorIndex,
          expandable: hasChildren,
          expanded: _expanded,
          onToggleExpand: () => setState(() => _expanded = !_expanded),
          onTap: () => openCategory(context, widget.section),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Column(
                  children: [
                    for (var j = 0; j < children.length; j++)
                      CategoryCard(
                        category: children[j],
                        lang: lang,
                        colorIndex: widget.colorIndex + j + 1,
                        inset: true,
                        onTap: () => openCategory(context, children[j]),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
