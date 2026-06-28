import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/core/app_toast.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

/// Win-screenshot ("evidence") upload: attach a screenshot, paste the Room ID
/// and submit. Opened from the Ludo match-list header.
class UploadEvidenceScreen extends StatefulWidget {
  const UploadEvidenceScreen({super.key});

  @override
  State<UploadEvidenceScreen> createState() => _UploadEvidenceScreenState();
}

class _UploadEvidenceScreenState extends State<UploadEvidenceScreen> {
  final _roomId = TextEditingController();
  File? _pickedFile;

  @override
  void dispose() {
    _roomId.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 45, // Automatic native compression to ~45% quality (highly readable but small size)
      );
      if (file != null) {
        final localFile = File(file.path);
        final sizeKb = await localFile.length() / 1024;
        setState(() {
          _pickedFile = localFile;
        });
        AppToast.success('Screenshot attached (${sizeKb.toStringAsFixed(1)} KB)');
      }
    } catch (e) {
      AppToast.error('Error selecting image: $e');
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      AppToast.warning('Clipboard is empty');
      return;
    }
    _roomId.text = text;
    AppToast.info('Pasted Room ID: $text');
  }

  void _submit() {
    if (_pickedFile == null) {
      AppToast.warning('আগে স্ক্রিনশট আপলোড করুন');
      return;
    }
    if (_roomId.text.trim().isEmpty) {
      AppToast.warning('Room ID দিন');
      return;
    }
    Get.back();
    AppToast.success('Evidence submitted — under review');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Upload Evidence')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _UploadBox(pickedFile: _pickedFile, onTap: _pickImage),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _roomId,
              style: AppTextStyles.body1.copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Room ID',
                fillColor: context.cSurface,
                suffixIcon: IconButton(
                  tooltip: 'Paste',
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste_rounded,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'SUBMIT',
              icon: Icons.check_rounded,
              variant: ButtonVariant.green,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
            _note(context, 'স্ক্রিনশট আপলোড না করলে আপনি প্রাইজ পাবেন না।'),
            _note(context,
                'উলটা পালটা ছবি/স্ক্রিনশট আপলোড করলে আপনাকে এপ থেকে চিরকালের জন্য ব্যান করে দেওয়া হবে।'),
            _note(context,
                'স্ক্রিনশট আপলোড করেও বিজয়ী পুরস্কার না পেলে সাপোর্টে যোগাযোগ করুন।'),
          ],
        ),
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 7, color: AppColors.matchesGreen),
          ),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body1
                    .copyWith(color: context.cTextDim, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final File? pickedFile;
  final VoidCallback onTap;
  const _UploadBox({required this.pickedFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final attached = pickedFile != null;
    final color = attached ? AppColors.matchesGreen : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: attached
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    pickedFile!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Screenshot attached — tap to change',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 56,
                      color: color),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                      'Click here to upload image',
                      style: AppTextStyles.title
                          .copyWith(fontSize: 14, color: context.cTextDim)),
                ],
              ),
      ),
    );
  }
}
