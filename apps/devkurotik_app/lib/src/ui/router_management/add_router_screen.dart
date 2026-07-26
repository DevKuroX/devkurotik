/// Add Router screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/router_model.dart';
import '../../providers/router_providers.dart';
import 'widgets/router_form_widget.dart';

/// Screen for adding a new router.
class AddRouterScreen extends ConsumerStatefulWidget {
  const AddRouterScreen({super.key});

  @override
  ConsumerState<AddRouterScreen> createState() => _AddRouterScreenState();
}

class _AddRouterScreenState extends ConsumerState<AddRouterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RouterFormData _data;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _data = RouterFormData();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Router'),
        actions: [
          _submitting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  key: const Key('save_router_btn'),
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              key: const Key('add_router_error'),
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: RouterFormWidget(
              formKey: _formKey,
              data: _data,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final router = RouterModel(
        id: _generateId(),
        name: _data.nameController.text.trim(),
        host: _data.hostController.text.trim(),
        port: int.parse(_data.portController.text.trim()),
        username: _data.usernameController.text.trim(),
        group: _data.selectedGroup,
        note:
            _data.noteController.text.trim().isEmpty
                ? null
                : _data.noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(routerListProvider.notifier).addRouter(
        router: router,
        password: _data.passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Generate a deterministic UUID-style id using current time + hash.
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hash = _data.nameController.text.hashCode.abs();
    return '${now.toRadixString(16)}-${hash.toRadixString(16)}';
  }
}
