import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dena_pawna/core/photo/photo.dart';
import 'package:dena_pawna/features/auth/auth_service.dart';
import 'package:dena_pawna/features/profile/widgets/profile_avatar.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet(this.acc, {super.key});
  final Account acc;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final _name = TextEditingController(text: widget.acc.name);
  late String _photo = widget.acc.photo;
  String? _err;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('ক্যামেরা'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('গ্যালারি'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_photo.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('ছবি মুছুন'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = '');
                },
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final path = await pickCompressedPhoto(context, source);
    if (path != null && mounted) setState(() => _photo = path);
  }

  Future<void> _save() async {
    final old = widget.acc.photo;
    final msg = await AuthService.instance.updateProfile(
      name: _name.text,
      photo: _photo,
    );
    if (!mounted) return;
    if (msg != null) {
      setState(() => _err = msg);
      return;
    }
    if (old.isNotEmpty && old != _photo) await deletePhoto(old);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.acc.copyWith(name: _name.text, photo: _photo);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'প্রোফাইল এডিট',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pick,
                child: Stack(
                  children: [
                    ProfileAvatar(preview, radius: 44),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'আপনার নাম',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(
                _err!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('সেভ করুন')),
          ],
        ),
      ),
    );
  }
}
