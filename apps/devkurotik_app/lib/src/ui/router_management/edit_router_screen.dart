/// Edit Router screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/router_providers.dart';
import 'widgets/router_form_widget.dart';

/// Screen for editing an existing router.
class EditRouterScreen extends ConsumerStatefulWidget {
  const EditRouterScreen({super.key, required this.routerId});

  final String routerId;

  @override
  ConsumerState<EditRouterScreen> createState() => _EditRouterScreenState();
}

class _EditRouterScreenState extends ConsumerState<EditRouterScreen> {
  final _formKey = GlobalKey<FormState>();
  RouterFormData? _data;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _notFoundMessage;

  @override
  void initState() {
    super.initState();
    _loadRouter();
  }

  Future<void> _loadRouter() async {
    final repo = ref.read(routerRepositoryProvider);
    final router = await repo.getRouter(widget.routerId);
    if (!mounted) return;

    if (router == null) {
      setState(() {
        _notFoundMessage = 'Router not found.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _data = RouterFormData(
        name: router.name,
        host: router.host,
        port: router.port,
        username: router.username,
        group: router.group,
        note: router.note,
        // Password intentionally blank — user must re-enter to change.
      );
      _loading = false;
    });
  }

  @override
  void dispose() {
    _data?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFoundMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Router')),
        body: Center(
          key: const Key('edit_router_not_found'),
          child: Text(_notFoundMessage!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Router'),
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
                  key: const Key('update_router_btn'),
                  onPressed: _submit,
                  child: const Text('Update'),
                ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              key: const Key('edit_router_error'),
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
              data: _data!,
              isEdit: true,
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
      final current =
          (ref.read(routerListProvider).valueOrNull ?? []).firstWhere(
        (r) => r.id == widget.routerId,
      );

      final updated = current.copyWith(
        name: _data!.nameController.text.trim(),
        host: _data!.hostController.text.trim(),
        port: int.parse(_data!.portController.text.trim()),
        username: _data!.usernameController.text.trim(),
        group: _data!.selectedGroup,
        note:
            _data!.noteController.text.trim().isEmpty
                ? null
                : _data!.noteController.text.trim(),
      );

      final newPassword =
          _data!.passwordController.text.isEmpty
              ? null
              : _data!.passwordController.text;

      await ref.read(routerListProvider.notifier).updateRouter(
        router: updated,
        password: newPassword,
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
}
