import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../utils/themes.dart';
import 'app_button.dart';
import 'page_layout.dart';

class ApiForm extends StatefulWidget {
  const ApiForm({
    super.key,
    required this.title,
    required this.path,
    required this.fields,
    required this.dateKey,
    required this.dateLabel,
    required this.submitLabel,
    required this.successMessage,
    this.includeTime = false,
    this.initialValues = const {},
  });

  final String title;
  final String path;
  final Map<String, String> fields;
  final String dateKey;
  final String dateLabel;
  final String submitLabel;
  final String successMessage;
  final bool includeTime;
  final Map<String, String> initialValues;

  @override
  State<ApiForm> createState() => _ApiFormState();
}

class _ApiFormState extends State<ApiForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  DateTime? _date;
  bool _busy = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final key in widget.fields.keys)
        key: TextEditingController(text: widget.initialValues[key])
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: _date ?? now.add(const Duration(days: 1)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 5));
    if (date == null || !mounted) return;
    var selected = DateTime(date.year, date.month, date.day, 23, 59);
    if (widget.includeTime) {
      final time = await showTimePicker(
          context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
      if (time == null || !mounted) return;
      selected =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    if (mounted) {
      setState(() {
        _date = selected;
        _message = null;
        _isSuccess = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || !_date!.isAfter(DateTime.now())) {
      setState(() {
        _message =
            'Choose a date${widget.includeTime ? ' and time' : ''} in the future.';
        _isSuccess = false;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await context.read<ApiService>().post(widget.path, {
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
        widget.dateKey: _date!.toUtc().toIso8601String(),
      });
      if (mounted) {
        for (final controller in _controllers.values) {
          controller.clear();
        }
        setState(() {
          _date = null;
          _message = widget.successMessage;
          _isSuccess = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Unable to save. Please check your details and try again.';
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageLayout(
        title: widget.title,
        maxWidth: 680,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final field in widget.fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _controllers[field.key],
                        enabled: !_busy,
                        maxLines: field.key == 'description' ? 5 : 1,
                        decoration: InputDecoration(labelText: field.value),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter ${field.value.toLowerCase()}'
                                : null,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    label: Text(
                      _date == null
                          ? widget.dateLabel
                          : (widget.includeTime
                                  ? DateFormat.yMMMd().add_jm()
                                  : DateFormat.yMMMd())
                              .format(_date!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: widget.submitLabel,
                    loading: _busy,
                    isFullWidth: true,
                    onPressed: _submit,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess
                              ? AppColors.successBorder
                              : AppColors.errorBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 18,
                            color: _isSuccess
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
