import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music/models/user.dart';
import 'package:music/services/api_service.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({required this.user});
  final User user;

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final ApiService apiService = ApiService();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController bioController;
  XFile? profile;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    bioController = TextEditingController(text: widget.user.bio);
  }

  void pilih() async {
    profile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {}); // refresh image preview
  }

  void _update(BuildContext context) async {
    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      final updateUser = User(
        id: widget.user.id,
        name: nameController.text,
        email: emailController.text,
        bio: bioController.text,
      );

      final response = await apiService.updateProfile(updateUser, profile);
      Navigator.pop(context);

      if (response['success'] == true) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.bottomSlide,
          dismissOnTouchOutside: false,
          title: "Sukses",
          desc: response['message'],
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      } else {
        AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.bottomSlide,
            dismissOnTouchOutside: false,
            title: "Error",
            desc: response['message'].toString(),
            btnOkOnPress: () {},
            btnOkColor: Colors.red)
          .show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF7643), Color(0xFFFF9E6D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
        child: Column(
          children: [
            // Foto Profil
            ProfilePic(
              image: widget.user.profile,
              imageUploadBtnPress: pilih,
            ),
            const SizedBox(height: 24),

            // Form Input
            Card(
              elevation: 3,
              shadowColor: Colors.orange.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Column(
                  children: [
                    UserInfoEditField(
                      text: "Nama",
                      icon: Icons.person_outline,
                      child: TextFormField(
                        controller: nameController,
                        decoration: _inputStyle("Masukkan nama"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    UserInfoEditField(
                      text: "Email",
                      icon: Icons.email_outlined,
                      child: TextFormField(
                        controller: emailController,
                        decoration: _inputStyle("Masukkan email"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    UserInfoEditField(
                      text: "Bio",
                      icon: Icons.info_outline,
                      child: TextFormField(
                        controller: bioController,
                        decoration: _inputStyle("Masukkan bio"),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tombol Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol batal
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Batal",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol simpan
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7643),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 3,
                    ),
                    onPressed: () => _update(context),
                    child: const Text(
                      "Simpan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFFF7643), width: 1.5),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  const ProfilePic({
    this.image,
    this.imageUploadBtnPress,
  });

  final String? image;
  final VoidCallback? imageUploadBtnPress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7643), Color(0xFFFF9E6D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: image != null
                  ? CachedNetworkImage(
                      imageUrl: "http://10.0.2.2:8000/images/$image",
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image,
                              size: 80, color: Colors.grey),
                    )
                  : const Icon(Icons.account_circle,
                      size: 110, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: InkWell(
            onTap: imageUploadBtnPress,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF7643),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        )
      ],
    );
  }
}

class UserInfoEditField extends StatelessWidget {
  const UserInfoEditField({
    super.key,
    required this.text,
    required this.child,
    required this.icon,
  });

  final String text;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFF7643), size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}