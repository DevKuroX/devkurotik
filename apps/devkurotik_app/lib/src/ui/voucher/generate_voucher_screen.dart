/// Phase 5 — Generate Voucher Screen.
///
/// Form for configuring and launching a voucher batch generation.
// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/hotspot_models.dart';
import '../../domain/models/voucher_models.dart';
import '../../domain/services/hotspot_service.dart';
import '../../providers/router_providers.dart';
import '../../providers/voucher_providers.dart';
import '../../routing/app_router.dart';

/// Screen for configuring voucher batch generation.
class GenerateVoucherScreen extends ConsumerStatefulWidget {
  const GenerateVoucherScreen({super.key});

  @override
  ConsumerState<GenerateVoucherScreen> createState() =>
      _GenerateVoucherScreenState();
}

class _GenerateVoucherScreenState extends ConsumerState<GenerateVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController(text: '10');
  final _prefixCtrl = TextEditingController();
  final _userLenCtrl = TextEditingController(text: '8');
  final _passLenCtrl = TextEditingController(text: '8');
  final _limitUptimeCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  VoucherMode _mode = VoucherMode.voucher;
  VoucherCharSet _charSet = VoucherCharSet.digitMixed;
  String? _selectedProfile;
  List<HotspotProfile> _profiles = [];
  bool _loadingProfiles = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _prefixCtrl.dispose();
    _userLenCtrl.dispose();
    _passLenCtrl.dispose();
    _limitUptimeCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final router = ref.read(activeRouterProvider);
    if (router == null) return;
    final password = await ref.read(routerRepositoryProvider).getPassword(router.id);
    if (password == null) return;

    setState(() => _loadingProfiles = true);
    try {
      const service = HotspotService();
      final profiles = await service.listProfiles(
        router: router,
        password: password,
      );
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _loadingProfiles = false;
          if (profiles.isNotEmpty && _selectedProfile == null) {
            _selectedProfile = profiles.first.name;
          }
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _loadingProfiles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(voucherActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Vouchers')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile selection
            _SectionHeader(title: 'Profile & Validity'),
            const SizedBox(height: 8),
            _loadingProfiles
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? _ProfileFallbackField(
                        onChanged: (v) => _selectedProfile = v,
                      )
                    : DropdownButtonFormField<String>(
                        key: const Key('profile_dropdown'),
                        // ignore: deprecated_member_use
                        value: _selectedProfile,
                        decoration: const InputDecoration(
                          labelText: 'Profile',
                          border: OutlineInputBorder(),
                        ),
                        items: _profiles
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.name,
                                child: Text(p.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProfile = v),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Select a profile' : null,
                      ),
            const SizedBox(height: 12),
            // Profile/validity preview
            if (_selectedProfile != null) ...[
              _ProfilePreviewCard(
                profile: _profiles
                    .where((p) => p.name == _selectedProfile)
                    .firstOrNull,
                profileName: _selectedProfile!,
              ),
              const SizedBox(height: 12),
            ],

            // Generation mode
            _SectionHeader(title: 'Mode'),
            const SizedBox(height: 8),
            DropdownButtonFormField<VoucherMode>(
              key: const Key('mode_dropdown'),
              // ignore: deprecated_member_use
              value: _mode,
              decoration: const InputDecoration(
                labelText: 'Voucher Mode',
                border: OutlineInputBorder(),
              ),
              items: VoucherMode.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        m == VoucherMode.voucher
                            ? 'Voucher (user = password)'
                            : 'User + Pass (separate)',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _mode = v ?? VoucherMode.voucher),
            ),
            const SizedBox(height: 12),

            // Quantity
            _SectionHeader(title: 'Batch Size'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('quantity_field'),
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity (1–500)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 500) {
                  return 'Enter a number between 1 and 500';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Character set
            _SectionHeader(title: 'Character Set'),
            const SizedBox(height: 8),
            DropdownButtonFormField<VoucherCharSet>(
              key: const Key('charset_dropdown'),
              // ignore: deprecated_member_use
              value: _charSet,
              decoration: const InputDecoration(
                labelText: 'Character Set',
                border: OutlineInputBorder(),
              ),
              items: VoucherCharSet.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _charSet = v ?? VoucherCharSet.digitMixed),
            ),
            const SizedBox(height: 12),

            // Prefix + Username length
            _SectionHeader(title: 'Credentials'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: const Key('prefix_field'),
                    controller: _prefixCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prefix (optional)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final err = VoucherValidation.validatePrefix(v);
                        if (err != null) return err;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('username_length_field'),
                    controller: _userLenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'User Len',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 3 || n > 32) {
                        return '3–32';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_mode == VoucherMode.userpass) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('password_length_field'),
                controller: _passLenCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password Length',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 3 || n > 32) {
                    return 'Password length must be 3–32';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),

            // Optional fields
            _SectionHeader(title: 'Optional'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('limit_uptime_field'),
              controller: _limitUptimeCtrl,
              decoration: const InputDecoration(
                labelText: 'Limit Uptime (e.g. 1h, 1d)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                return VoucherValidation.validateLimitUptime(v);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('comment_field'),
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Generate button
            if (actionsAsync is AsyncLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                key: const Key('generate_btn'),
                onPressed: _onGenerate,
                icon: const Icon(Icons.add_card),
                label: const Text('Generate Vouchers'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('one_touch_btn'),
                onPressed: _onOneTouch,
                icon: const Icon(Icons.print),
                label: const Text('One-Touch: Generate + Print'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onGenerate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final router = ref.read(activeRouterProvider);
    if (router == null) return;

    final params = _buildParams(router.host, router.id);
    try {
      final batch = await ref
          .read(voucherActionsProvider.notifier)
          .generateAndPush(params);

      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.voucherPreview,
        extra: batch,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onOneTouch() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final router = ref.read(activeRouterProvider);
    if (router == null) return;

    final params = _buildParams(router.host, router.id);
    try {
      await ref
          .read(voucherActionsProvider.notifier)
          .oneTouchGenerateAndPrint(
            params,
            routerName: router.name,
            template: ref.read(voucherTemplateProvider),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher sent to print!')),
      );
      context.pop();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  VoucherGenerationParams _buildParams(String routerHost, String routerId) {
    return VoucherGenerationParams(
      routerId: routerId,
      routerHost: routerHost,
      profileName: _selectedProfile ?? '',
      quantity: int.tryParse(_quantityCtrl.text) ?? 10,
      mode: _mode,
      charSet: _charSet,
      usernameLength: int.tryParse(_userLenCtrl.text) ?? 8,
      passwordLength: int.tryParse(_passLenCtrl.text) ?? 8,
      prefix: _prefixCtrl.text.trim(),
      limitUptime:
          _limitUptimeCtrl.text.trim().isEmpty ? null : _limitUptimeCtrl.text.trim(),
      comment:
          _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _ProfileFallbackField extends StatelessWidget {
  const _ProfileFallbackField({required this.onChanged});
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('profile_field'),
      decoration: const InputDecoration(
        labelText: 'Profile name',
        border: OutlineInputBorder(),
        hintText: 'e.g. default',
      ),
      onChanged: onChanged,
      validator: (v) => (v == null || v.isEmpty) ? 'Profile is required' : null,
    );
  }
}

class _ProfilePreviewCard extends StatelessWidget {
  const _ProfilePreviewCard({
    required this.profileName,
    this.profile,
  });

  final String profileName;
  final HotspotProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Preview',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              profileName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (profile?.validity != null) ...[
              const SizedBox(height: 2),
              Text(
                'Validity: ${profile!.validity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (profile?.rateLimit != null) ...[
              Text(
                'Rate: ${profile!.rateLimit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
