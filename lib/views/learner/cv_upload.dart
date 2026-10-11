import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
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

  Future<void> _pick() async {
    setState(() { _busy = true; _message = null; });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'], withData: true);
      if (!mounted || result == null) return;
      final file = result.files.single;
      if (file.size == 0 || file.size > AppConstants.maxCvBytes || file.bytes == null) {
        setState(() { _file = null; _message = 'Choose a file up to 5 MB.'; });
      } else {
        setState(() => _file = file);
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'Unable to open the file picker. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final file = _file;
    if (file?.bytes == null) return;
    setState(() { _busy = true; _message = null; });
    try {
      await context.read<ApiService>().uploadCv(file!.name, file.bytes!);
      if (mounted) setState(() { _file = null; _message = 'Your CV was uploaded successfully.'; });
    } catch (_) {
      if (mounted) setState(() => _message = 'Unable to upload your CV. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageLayout(title: 'Upload your CV',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Choose your latest CV in PDF, DOC, or DOCX format. Maximum size: 5 MB.'),
      const SizedBox(height: 24),
      OutlinedButton.icon(onPressed: _busy ? null : _pick,
        icon: const Icon(Icons.attach_file), label: const Text('Choose CV')),
      if (_file != null) Padding(padding: const EdgeInsets.all(16), child: Text(_file!.name)),
      AppButton(label: 'Upload CV', loading: _busy, onPressed: _file == null ? null : _upload),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_message!)),
    ]),
  );
}
