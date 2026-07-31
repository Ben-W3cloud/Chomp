import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import 'repo_provider.dart';

final feedProvider = FutureProvider.autoDispose<List<FeedItem>>((ref) async {
  final data = ref.watch(chompDataServiceProvider);
  return data.getFeed();
});
