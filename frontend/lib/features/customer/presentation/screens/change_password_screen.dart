import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(customerAuthProvider.notifier)
          .changePassword(_old.text, _next.text);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: context.l10n.changePassword,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.md),
            children: [
              Material(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(context.l10n.changeTempPasswordMessage))),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _old,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: context.l10n.oldPassword),
                  validator: (v) =>
                      v == null || v.isEmpty ? context.l10n.required : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _next,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: context.l10n.newPassword),
                  validator: (v) {
                    if (v == null || v.length < 8) return context.l10n.minLength8;
                    if (v == _old.text) {
                      return context.l10n.newPasswordCannotMatch;
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: context.l10n.confirmPassword,
                      border: const OutlineInputBorder()),
                  validator: (v) =>
                      v != _next.text ? context.l10n.confirmationMismatch : null),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                        ? M3LoadingIndicator(size: 20, color: Colors.white)
                      : Text(context.l10n.savePassword)),
            ],
          ),
        ),
      );
}
