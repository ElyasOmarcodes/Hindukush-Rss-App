import 'package:flutter/material.dart';

import '../../core/config/feeds.dart';
import '../../data/models/article.dart';
import '../list/list_screen.dart';
import '../post/post_view_screen.dart';

void openPost(BuildContext context, Article article) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PostViewScreen(article: article)),
  );
}

void openCategory(BuildContext context, FeedCategory category) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ListScreen(category: category)),
  );
}
