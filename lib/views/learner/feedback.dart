import 'package:flutter/material.dart';
import '../../utils/validators.dart';
import '../../state/submission_controller.dart';
import '../../utils/themes.dart';
import '../../widgets/brand_logo.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, this.onSubmit});

  final Future<void> Function(Map<String, String> values)? onSubmit;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  static const _defaults = {
    'email': '',
    'category': 'Bug Report',
    'rating': '3',
    'comments': '',
  };

  // One state source for the whole form: values, validation, submitting.
  late final SubmissionController _form = SubmissionController(
    initialValues: _defaults,
    validators: {
      'email': (value) => FormValidators.email(value),
      'comments': (value) => FormValidators.feedback(value),
    },
  );

  double get _rating => double.tryParse(_form.valueOf('rating')) ?? 3.0;

  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'Program Feedback',
    'Account Issue',
  ];

  static const Color brandOrange = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color borderGrey = AppColors.border;

  @override
  void initState() {
    super.initState();
    _form.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _form.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _logFeedback(Map<String, String> values) async {
    debugPrint('--- NEW FEEDBACK RECEIVED ---');
    debugPrint('From: ${values['email']?.trim()}');
    debugPrint('Type: ${values['category']}');
    debugPrint('Rating: ${values['rating']}/5');
    debugPrint('Message: ${values['comments']?.trim()}');
  }

  Future<void> _submitFeedback() async {
    final ok = await _form.submit(widget.onSubmit ?? _logFeedback);
    if (!mounted) return;
    if (ok) {
      // Back to a clean form with the starting values.
      _emailController.clear();
      _feedbackController.clear();
      _form.reset();
      _defaults.forEach(_form.setValue);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your feedback has been submitted.'),
          backgroundColor: brandOrange,
        ),
      );
    } else if (_form.fieldErrors.isEmpty && _form.message != null) {
      // The request failed (not a validation problem): say so.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_form.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: textDark),
        title: const Text('Feedback'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandLogo()),
              const SizedBox(height: 24),
              const Text(
                'We value your feedback',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Let us know how we can improve your experience.',
                style: TextStyle(fontSize: 14, color: textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              const Text(
                'Email Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _form.setValue('email', value),
                decoration: InputDecoration(
                  errorText: _form.errorOf('email'),
                  hintText: 'name@example.com',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: brandOrange, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Feedback Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _form.valueOf('category'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: brandOrange, width: 1.5),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child:
                        Text(category, style: const TextStyle(color: textDark)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) _form.setValue('category', newValue);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Experience Rating',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textDark,
                    ),
                  ),
                  Text(
                    '${_rating.toInt()} / 5',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: brandOrange,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: brandOrange,
                  inactiveTrackColor: brandOrange.withValues(alpha: 0.15),
                  thumbColor: brandOrange,
                  overlayColor: brandOrange.withValues(alpha: 0.12),
                  valueIndicatorColor: brandOrange,
                ),
                child: Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  label: _rating.toInt().toString(),
                  onChanged: (double value) =>
                      _form.setValue('rating', value.toInt().toString()),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Feedback / Comments',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                onChanged: (value) => _form.setValue('comments', value),
                decoration: InputDecoration(
                  errorText: _form.errorOf('comments'),
                  hintText:
                      'Tell us what happened or what you\'d like to see...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: brandOrange, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _form.canSubmit ? _submitFeedback : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _form.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit feedback',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
