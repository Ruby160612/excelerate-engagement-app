import 'package:flutter/material.dart';
import '../../widgets/auth_form.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});
  @override
  Widget build(BuildContext context) => const AuthForm(signup: true);
}
