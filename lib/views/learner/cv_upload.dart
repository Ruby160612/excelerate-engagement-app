import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/themes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/page_layout.dart';

class CvUploadView extends StatefulWidget {
  const CvUploadView({super.key});

  @override
  State<CvUploadView> createState() => _CvUploadViewState();
}

class _CvUploadViewState extends State<CvUploadView> {
  bool _busy = false;
  PlatformFile? _file;
  String? _message;
  bool _isSuccess = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _isSuccess = false;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx'],
          withData: true);
      if (!mounted || result == null) return;
      final file = result.files.single;
      if (file.size == 0 ||
          file.size > AppConstants.maxCvBytes ||
          file.bytes == null) {
        setState(() {
          _file = null;
          _message = 'Choose a file up to 5 MB.';
          _isSuccess = false;
        });
      } else {
        setState(() => _file = file);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Unable to open the file picker. Please try again.';
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    if (_busy) return;
    final file = _file;
    if (file?.bytes == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await context.read<ApiService>().uploadCv(file!.name, file.bytes!);
      if (mounted) {
        setState(() {
          _file = null;
          _message = 'Your CV was uploaded successfully.';
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e is ApiException
              ? e.message
              : 'Unable to upload your CV. Please try again.';
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageLayout(
      title: 'Upload your CV',
      maxWidth: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: const Icon(Icons.cloud_upload_outlined,
                          size: 36, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose your latest CV in PDF, DOC, or DOCX format. Maximum size: 5 MB.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Choose CV'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  if (_file != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined,
                              color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _file!.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(_file!.size / 1024).toStringAsFixed(1)} KB',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Remove',
                            onPressed: _busy ? null : () => setState(() => _file = null),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Upload CV',
                    loading: _busy,
                    isFullWidth: true,
                    onPressed: _file == null || _busy ? null : _upload,
                  ),

                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? AppColors.successLight : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess ? AppColors.successBorder : AppColors.errorBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                            size: 18,
                            color: _isSuccess ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!_isSuccess && _file != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _busy ? null : _upload,
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
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
