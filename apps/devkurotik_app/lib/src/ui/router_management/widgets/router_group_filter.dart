/// Router group filter widget.
library;

import 'package:flutter/material.dart';

import '../../../domain/models/router_model.dart';

/// Horizontal chip bar for filtering routers by group.
class RouterGroupFilter extends StatelessWidget {
  const RouterGroupFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RouterGroup? selected;
  final ValueChanged<RouterGroup?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        key: const Key('group_filter_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: const Key('group_filter_all'),
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...RouterGroup.values.map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('group_filter_${g.name}'),
                label: Text(g.label),
                selected: selected == g,
                onSelected: (_) => onChanged(g == selected ? null : g),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
