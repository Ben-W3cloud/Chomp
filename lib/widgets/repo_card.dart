/// Repository card widget.
///
/// Displays a repository in the home screen list. Shows the repo name,
/// description, and watch status chip (AUTO for auto-watched, WATCHED
/// for manually watched repos).
///
/// Tapping the card navigates to the repo detail screen.

import 'package:flutter/material.dart';
import '../models/repo.dart';

class RepoCard extends StatelessWidget {
  const RepoCard({super.key, required this.repo, this.onTap});
  final Repo repo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(repo.name),
        subtitle: Text(repo.description ?? repo.fullName),
        trailing: repo.isAutoWatched
            ? const Chip(label: Text('AUTO'))
            : repo.isManuallyWatched
                ? const Chip(label: Text('WATCHED'))
                : null,
      ),
    );
  }
}
