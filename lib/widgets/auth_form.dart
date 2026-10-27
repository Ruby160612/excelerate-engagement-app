import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/submission_controller.dart';
import '../utils/constants.dart';
import 'app_button.dart';
import 'brand_logo.dart';
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

  // Form values and the submit status (idle -> submitting -> success/error)
  // live in one controller; the screen only reads from it.
  late final SubmissionController _form = SubmissionController(
    initialValues: const {
      'name': '',
      'email': '',
      'password': '',
      'invitation': '',
    },
  );
  bool get _busy => _form.isSubmitting;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => _form.setValue('name', _name.text));
    _email.addListener(() => _form.setValue('email', _email.text));
    _password.addListener(() => _form.setValue('password', _password.text));
    _invitation
        .addListener(() => _form.setValue('invitation', _invitation.text));
    _form.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _form.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _invitation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    // The controller blocks repeat taps while the request is running.
    final ok = await _form.submit((values) async {
      final auth = context.read<AuthService>();
      if (widget.signup) {
        await auth.signup(values['name']!, values['email']!,
            values['password']!, values['invitation']!);
      } else {
        await auth.login(values['email']!, values['password']!);
      }
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else if (_form.message != null) {
      setState(() => _error = widget.signup
          ? 'Unable to create your account. Check your details and invitation.'
          : 'Unable to sign in. Check your credentials and connection.');
      // Back to idle so a retry starts clean (typed values are kept).
      _form.reset(keepValues: true);
    }
  }

  @override
  Widget build(BuildContext context) => PageLayout(
        title: AppConstants.name,
        appBarTitle: const SizedBox.shrink(),
        child: AutofillGroup(
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandLogo(showTagline: true)),
                    const SizedBox(height: 32),
                    Text(
                        widget.signup
                            ? 'Join your talent community'
                            : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                        widget.signup
                            ? 'Create an account with your private invitation.'
                            : 'Sign in to continue your development journey.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    if (widget.signup) ...[
                      TextFormField(
                          controller: _name,
                          decoration:
                              const InputDecoration(labelText: 'Full name'),
                          autofillHints: const [AutofillHints.name],
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your name'
                                  : null),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value.trim())
                            ? 'Enter a valid email'
                            : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: [
                          widget.signup
                              ? AutofillHints.newPassword
                              : AutofillHints.password
                        ],
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          if (widget.signup && value.length < 8) {
                            return 'Use at least 8 characters';
                          }
                          return null;
                        }),
                    if (widget.signup) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _invitation,
                          decoration: const InputDecoration(
                              labelText: 'Invitation code'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter your invitation code'
                                  : null),
                    ],
                    if (_error != null ||
                        context.watch<AuthService>().initializationError !=
                            null)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                              _error ??
                                  context
                                      .watch<AuthService>()
                                      .initializationError!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    const SizedBox(height: 24),
                    AppButton(
                        label: widget.signup ? 'Create account' : 'Sign in',
                        loading: _busy,
                        onPressed: _submit),
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                context,
                                widget.signup
                                    ? AppRoutes.login
                                    : AppRoutes.signup),
                        child: Text(widget.signup
                            ? 'Already a member? Sign in'
                            : 'Have an invitation? Create an account')),
                  ],
                ))),
      );
}
