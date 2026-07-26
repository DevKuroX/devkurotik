/// Phase 4 — Edit Hotspot User Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/hotspot_models.dart';
import '../../providers/hotspot_providers.dart';

/// Screen for editing an existing hotspot user.
///
/// Receives the existing [HotspotUser] via route `extra`.
class EditHotspotUserScreen extends ConsumerStatefulWidget {
  const EditHotspotUserScreen({
    super.key,
    required this.userId,
    required this.user,
  });

  final String userId;
  final HotspotUser user;

  @override
  ConsumerState<EditHotspotUserScreen> createState() =>
      _EditHotspotUserScreenState();
}

class _EditHotspotUserScreenState
    extends ConsumerState<EditHotspotUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _commentCtrl;
  late final TextEditingController _macCtrl;
  late final TextEditingController _limitUptimeCtrl;

  late String _selectedProfile;
  late bool _disabled;
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _passwordCtrl = TextEditingController(text: widget.user.password);
    _commentCtrl = TextEditingController(text: widget.user.comment ?? '');
    _macCtrl = TextEditingController(text: widget.user.macAddress ?? '');
    _limitUptimeCtrl =
        TextEditingController(text: widget.user.limitUptime ?? '');
    _selectedProfile = widget.user.profile;
    _disabled = widget.user.disabled;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _commentCtrl.dispose();
    _macCtrl.dispose();
    _limitUptimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotspotAsync = ref.watch(activeHotspotProvider);
    final profiles = hotspotAsync.valueOrNull?.profiles ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.user.name}'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              key: const Key('edit_user_save_button'),
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Username
            TextFormField(
              key: const Key('edit_user_name_field'),
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username *',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  HotspotUserValidation.validateName(v ?? ''),
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              key: const Key('edit_user_password_field'),
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Password *',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  HotspotUserValidation.validatePassword(v ?? ''),
            ),
            const SizedBox(height: 12),

            // Profile
            if (profiles.isEmpty)
              // Fall back to text field if profiles not yet loaded.
              TextFormField(
                key: const Key('edit_user_profile_field'),
                initialValue: _selectedProfile,
                decoration: const InputDecoration(labelText: 'Profile *'),
                onChanged: (v) => setState(() => _selectedProfile = v),
                validator: (v) =>
                    HotspotUserValidation.validateProfile(v ?? ''),
              )
            else
              DropdownButtonFormField<String>(
                key: const Key('edit_user_profile_dropdown'),
                initialValue: profiles.any((p) => p.name == _selectedProfile)
                    ? _selectedProfile
                    : profiles.first.name,
                decoration: const InputDecoration(labelText: 'Profile *'),
                items: profiles
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.name,
                        child: Text(p.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedProfile = v);
                },
              ),
            const SizedBox(height: 12),

            // Limit uptime
            TextFormField(
              key: const Key('edit_user_limit_uptime_field'),
              controller: _limitUptimeCtrl,
              decoration: const InputDecoration(
                labelText: 'Limit Uptime (optional)',
                helperText: 'e.g. 1h, 2h30m, 1d. Leave empty to remove.',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  HotspotUserValidation.validateLimitUptime(v),
            ),
            const SizedBox(height: 12),

            // Comment
            TextFormField(
              key: const Key('edit_user_comment_field'),
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // MAC address
            TextFormField(
              key: const Key('edit_user_mac_field'),
              controller: _macCtrl,
              decoration: const InputDecoration(
                labelText: 'MAC Address (optional)',
                helperText: 'XX:XX:XX:XX:XX:XX',
              ),
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  HotspotUserValidation.validateMacAddress(v),
            ),
            const SizedBox(height: 12),

            // Disabled toggle
            SwitchListTile(
              key: const Key('edit_user_disabled_toggle'),
              title: const Text('Disabled'),
              value: _disabled,
              onChanged: (v) => setState(() => _disabled = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final update = HotspotUserUpdate(
      name: _nameCtrl.text.trim(),
      password: _passwordCtrl.text,
      profile: _selectedProfile,
      limitUptime: _limitUptimeCtrl.text.trim().isEmpty
          ? ''
          : _limitUptimeCtrl.text.trim(),
      comment: _commentCtrl.text.trim(),
      macAddress: _macCtrl.text.trim(),
      disabled: _disabled,
    );

    setState(() => _saving = true);
    try {
      await ref
          .read(hotspotActionsProvider.notifier)
          .updateUser(widget.userId, update);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "${widget.user.name}" updated.')),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll(
                    RegExp(r'=password=[^\s,]+'),
                    '=password=***',
                  ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
