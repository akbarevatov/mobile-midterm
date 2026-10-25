import 'package:flutter/material.dart';

import '../../widgets/common/app_scope.dart';
import '../../widgets/common/empty_state.dart';
import 'home_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final entries = app.recentActivity;
    return Scaffold(
      appBar: AppBar(title: Text(s.recentActivity)),
      body: entries.isEmpty
          ? EmptyState(icon: Icons.history, title: s.noActivity)
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  ActivityTile(entry: entries[index]),
            ),
    );
  }
}
