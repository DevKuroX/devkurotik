/// Delete confirmation dialog.
library;

import 'package:flutter/material.dart';

/// Confirmation dialog shown before deleting a router.
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({super.key, required this.routerName});

  final String routerName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('delete_confirmation_dialog'),
      title: const Text('Delete Router'),
      content: Text(
        'Are you sure you want to delete "$routerName"?\n'
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          key: const Key('delete_cancel_btn'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('delete_confirm_btn'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
