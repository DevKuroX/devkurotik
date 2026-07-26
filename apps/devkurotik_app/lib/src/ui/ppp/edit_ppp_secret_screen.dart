/// Phase 7 — Edit PPP Secret Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ppp_models.dart';
import '../../providers/ppp_providers.dart';

/// Form screen for editing an existing PPP secret.
class EditPppSecretScreen extends ConsumerStatefulWidget {
  const EditPppSecretScreen({
    super.key,
    required this.secretId,
    required this.secret,
  });

  final String secretId;
  final PppSecret secret;

  @override
  ConsumerState<EditPppSecretScreen> createState() =>
      _EditPppSecretScreenState();
}

class _EditPppSecretScreenState extends ConsumerState<EditPppSecretScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _profileController;
  late final TextEditingController _commentController;
  late final TextEditingController _localAddressController;
  late final TextEditingController _remoteAddressController;
  late final TextEditingController _callerIdController;

  late PppServiceType _service;
  late bool _disabled;
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.secret;
    _nameController = TextEditingController(text: s.name);
    _passwordController = TextEditingController(text: s.password);
    _profileController = TextEditingController(text: s.profile);
    _commentController = TextEditingController(text: s.comment ?? '');
    _localAddressController =
        TextEditingController(text: s.localAddress ?? '');
    _remoteAddressController =
        TextEditingController(text: s.remoteAddress ?? '');
    _callerIdController = TextEditingController(text: s.callerId ?? '');
    _service = s.service;
    _disabled = s.disabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _profileController.dispose();
    _commentController.dispose();
    _localAddressController.dispose();
    _remoteAddressController.dispose();
    _callerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${widget.secret.name}"'),
        actions: [
          TextButton(
            key: const Key('ppp_edit_save_button'),
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _saving
          ? const Center(
              key: Key('ppp_edit_saving'),
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Credentials ──────────────────────────────────────────
                  Text(
                    'Credentials',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('ppp_edit_name_field'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        PppSecretValidation.validateName(v ?? ''),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('ppp_edit_password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'Leave unchanged to keep existing password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // ── Service & Profile ────────────────────────────────────
                  Text(
                    'Service',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PppServiceType>(
                    key: const Key('ppp_edit_service_field'),
                    // ignore: deprecated_member_use
                    value: _service,
                    decoration: const InputDecoration(
                      labelText: 'Service',
                      border: OutlineInputBorder(),
                    ),
                    items: PppServiceType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _service = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('ppp_edit_profile_field'),
                    controller: _profileController,
                    decoration: const InputDecoration(
                      labelText: 'Profile *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        PppSecretValidation.validateProfile(v ?? ''),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // ── Optional fields ──────────────────────────────────────
                  Text(
                    'Optional',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('ppp_edit_local_address_field'),
                    controller: _localAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Local Address (IP or pool)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => PppSecretValidation.validateIpOrEmpty(
                        v, 'Local address'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('ppp_edit_remote_address_field'),
                    controller: _remoteAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Remote Address (IP or pool)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => PppSecretValidation.validateIpOrEmpty(
                        v, 'Remote address'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('ppp_edit_caller_id_field'),
                    controller: _callerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Caller ID',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('ppp_edit_comment_field'),
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('ppp_edit_disabled_switch'),
                    title: const Text('Disabled'),
                    value: _disabled,
                    onChanged: (v) => setState(() => _disabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('ppp_edit_submit_button'),
                    onPressed: _save,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final update = PppSecretUpdate(
      name: _nameController.text.trim(),
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
      service: _service,
      profile: _profileController.text.trim(),
      disabled: _disabled,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      localAddress: _localAddressController.text.trim().isEmpty
          ? null
          : _localAddressController.text.trim(),
      remoteAddress: _remoteAddressController.text.trim().isEmpty
          ? null
          : _remoteAddressController.text.trim(),
      callerId: _callerIdController.text.trim().isEmpty
          ? null
          : _callerIdController.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await ref
          .read(pppActionsProvider.notifier)
          .updateSecret(widget.secretId, update);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Secret "${update.name}" updated.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
