import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'empty_state.dart';

class MissingItemScreen extends StatelessWidget {
  const MissingItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: context.s.deleted,
      ),
    );
  }
}
