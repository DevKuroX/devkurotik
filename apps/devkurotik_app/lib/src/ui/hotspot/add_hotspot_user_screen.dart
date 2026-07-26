/// Phase 4 — Add Hotspot User Screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/hotspot_models.dart';
import '../../providers/hotspot_providers.dart';

/// Screen for creating a new hotspot user.
class AddHotspotUserScreen extends ConsumerStatefulWidget {
  const AddHotspotUserScreen({super.key});

  @override
  ConsumerState<AddHotspotUserScreen> createState() =>
      _AddHotspotUserScreenState();
}

class _AddHotspotUserScreenState
    extends ConsumerState<AddHotspotUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _limitUptimeCtrl = TextEditingController();

  String _selectedProfile = '';
  bool _disabled = false;
  bool _obscurePassword = true;
  bool _saving = false;

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

    // Default profile selection.
    if (_selectedProfile.isEmpty && profiles.isNotEmpty) {
      _selectedProfile = profiles.first.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Hotspot User'),
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
              key: const Key('add_user_save_button'),
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
              key: const Key('add_user_name_field'),
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username *',
                helperText: 'Alphanumeric, hyphens, underscores, dots only',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => HotspotUserValidation.validateName(v ?? ''),
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              key: const Key('add_user_password_field'),
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
              const Text(
                'No profiles available. Connect to router first.',
                style: TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<String>(
                key: const Key('add_user_profile_dropdown'),
                initialValue: _selectedProfile.isEmpty ? null : _selectedProfile,
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
                validator: (v) =>
                    HotspotUserValidation.validateProfile(v ?? ''),
              ),
            const SizedBox(height: 12),

            // Optional: limit uptime
            TextFormField(
              key: const Key('add_user_limit_uptime_field'),
              controller: _limitUptimeCtrl,
              decoration: const InputDecoration(
                labelText: 'Limit Uptime (optional)',
                helperText: 'e.g. 1h, 2h30m, 1d',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  HotspotUserValidation.validateLimitUptime(v),
            ),
            const SizedBox(height: 12),

            // Optional: comment
            TextFormField(
              key: const Key('add_user_comment_field'),
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Optional: MAC address
            TextFormField(
              key: const Key('add_user_mac_field'),
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
              key: const Key('add_user_disabled_toggle'),
              title: const Text('Create as Disabled'),
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

    final params = HotspotUserCreate(
      name: _nameCtrl.text.trim(),
      password: _passwordCtrl.text,
      profile: _selectedProfile,
      limitUptime: _limitUptimeCtrl.text.trim().isEmpty
          ? null
          : _limitUptimeCtrl.text.trim(),
      comment: _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim(),
      macAddress: _macCtrl.text.trim().isEmpty ? null : _macCtrl.text.trim(),
      disabled: _disabled,
    );

    setState(() => _saving = true);
    try {
      await ref.read(hotspotActionsProvider.notifier).addUser(params);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "${params.name}" created.'),
          ),
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
