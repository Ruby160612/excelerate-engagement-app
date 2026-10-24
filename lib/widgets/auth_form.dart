import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/themes.dart';
import '../utils/validators.dart';
import 'app_button.dart';
import 'page_layout.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, this.signup = false});
  final bool signup;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invitation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _invitation.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      if (widget.signup) {
        await auth.signup(
            _name.text, _email.text, _password.text, _invitation.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
      if (mounted) {
        if (widget.signup) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: AppColors.success,
            ),
          );
        }

        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : (widget.signup
                  ? 'Unable to create your account. Check your details and invitation.'
                  : 'Unable to sign in. Check your credentials and connection.');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initError = context.watch<AuthService>().initializationError;
    final activeError = _error ?? initError;

    return PageLayout(
      title: AppConstants.name,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.signup
                    ? 'Join your talent community'
                    : 'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.signup
                    ? 'Create an account with your private invitation.'
                    : 'Sign in to continue your development journey.',
              ),
              const SizedBox(height: 24),
              if (widget.signup) ...[
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  onChanged: (_) => _onFieldChanged(),
                  decoration: const InputDecoration(labelText: 'Full name'),
                  autofillHints: const [AutofillHints.name],
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _email,
                enabled: !_busy,
                onChanged: (_) => _onFieldChanged(),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: FormValidators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                onChanged: (_) => _onFieldChanged(),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: [
                  widget.signup
                      ? AutofillHints.newPassword
                      : AutofillHints.password
                ],
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    FormValidators.password(value, signup: widget.signup),
              ),
              if (widget.signup) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _invitation,
                  enabled: !_busy,
                  onChanged: (_) => _onFieldChanged(),
                  decoration:
                      const InputDecoration(labelText: 'Invitation code'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your invitation code'
                      : null,
                ),
              ],
              if (activeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeError,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _busy ? null : _submit,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Retry',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.signup ? 'Create account' : 'Sign in',
                loading: _busy,
                onPressed: _submit,
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context,
                        widget.signup
                            ? AppRoutes.login
                            : AppRoutes.signup),
                child: Text(
                  widget.signup
                      ? 'Already a member? Sign in'
                      : 'Have an invitation? Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
