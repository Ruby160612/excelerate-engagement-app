import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/page_layout.dart';

class ProfileCreationView extends StatefulWidget {
  const ProfileCreationView({super.key});
  @override
  State<ProfileCreationView> createState() => _ProfileCreationViewState();
}

class _ProfileCreationViewState extends State<ProfileCreationView> {
  final _formKey = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _skills.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.createProfile(Profile(
          userId: auth.user!.id,
          headline: _headline.text.trim(),
          bio: _bio.text.trim(),
          skills: _skills.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (_) => false);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Unable to save your profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageLayout(
        title: 'Create your profile',
        child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Tell us about your experience and the skills you want to grow.'),
                const SizedBox(height: 24),
                TextFormField(
                    controller: _headline,
                    decoration: const InputDecoration(
                        labelText: 'Professional headline'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a headline'
                        : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _bio,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'About you'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Tell us about yourself'
                        : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _skills,
                    decoration: const InputDecoration(
                        labelText: 'Skills',
                        helperText: 'Separate skills with commas'),
                    validator: (v) =>
                        v == null || v.split(',').every((s) => s.trim().isEmpty)
                            ? 'Enter at least one skill'
                            : null),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_error!)),
                const SizedBox(height: 24),
                AppButton(
                    label: 'Save profile', loading: _busy, onPressed: _save),
              ],
            )),
      );
}
