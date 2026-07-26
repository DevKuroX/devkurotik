/// Shared router form for Add and Edit flows.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/router_model.dart';

/// Form data holder used by both Add and Edit screens.
class RouterFormData {
  RouterFormData({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    RouterGroup? group,
    String? note,
  }) : nameController = TextEditingController(text: name),
       hostController = TextEditingController(text: host),
       portController = TextEditingController(text: (port ?? 8728).toString()),
       usernameController = TextEditingController(text: username ?? 'admin'),
       passwordController = TextEditingController(text: password),
       noteController = TextEditingController(text: note),
       selectedGroup = group ?? RouterGroup.ungrouped;

  final TextEditingController nameController;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController noteController;
  RouterGroup selectedGroup;

  void dispose() {
    nameController.dispose();
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    noteController.dispose();
  }
}

/// Shared form widget for adding and editing routers.
///
/// Does not handle submission — the parent screen owns submit logic.
class RouterFormWidget extends StatefulWidget {
  const RouterFormWidget({
    super.key,
    required this.formKey,
    required this.data,
    this.isEdit = false,
  });

  final GlobalKey<FormState> formKey;
  final RouterFormData data;

  /// In edit mode the password field is optional (leave blank to keep current).
  final bool isEdit;

  @override
  State<RouterFormWidget> createState() => _RouterFormWidgetState();
}

class _RouterFormWidgetState extends State<RouterFormWidget> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextFormField(
            key: const Key('router_name_field'),
            controller: widget.data.nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name *',
              hintText: 'e.g. Office Router',
              prefixIcon: Icon(Icons.label),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // Host
          TextFormField(
            key: const Key('router_host_field'),
            controller: widget.data.hostController,
            decoration: const InputDecoration(
              labelText: 'Host / IP Address *',
              hintText: 'e.g. 192.168.88.1',
              prefixIcon: Icon(Icons.dns),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Host is required' : null,
          ),
          const SizedBox(height: 16),

          // Port
          TextFormField(
            key: const Key('router_port_field'),
            controller: widget.data.portController,
            decoration: const InputDecoration(
              labelText: 'API Port *',
              hintText: '8728',
              prefixIcon: Icon(Icons.settings_ethernet),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Port is required';
              final n = int.tryParse(v);
              if (n == null || n < 1 || n > 65535) {
                return 'Port must be 1–65535';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Username
          TextFormField(
            key: const Key('router_username_field'),
            controller: widget.data.usernameController,
            decoration: const InputDecoration(
              labelText: 'Username *',
              hintText: 'admin',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Username is required' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            key: const Key('router_password_field'),
            controller: widget.data.passwordController,
            decoration: InputDecoration(
              labelText:
                  widget.isEdit ? 'Password (leave blank to keep)' : 'Password *',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                key: const Key('toggle_password_btn'),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (!widget.isEdit && (v == null || v.isEmpty)) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Group
          DropdownButtonFormField<RouterGroup>(
            key: const Key('router_group_dropdown'),
            // ignore: deprecated_member_use
            value: widget.data.selectedGroup,
            decoration: const InputDecoration(
              labelText: 'Group',
              prefixIcon: Icon(Icons.folder),
            ),
            items: RouterGroup.values
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.label),
                  ),
                )
                .toList(),
            onChanged: (g) {
              if (g != null) {
                setState(() => widget.data.selectedGroup = g);
              }
            },
          ),
          const SizedBox(height: 16),

          // Note
          TextFormField(
            key: const Key('router_note_field'),
            controller: widget.data.noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
