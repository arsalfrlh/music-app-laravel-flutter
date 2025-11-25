import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music/models/song.dart';
import 'package:music/pages/artis/main/artis_footer_page.dart';
import 'package:music/services/api_service.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({required this.song});
  final Song song;

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final ApiService apiService = ApiService();
  late TextEditingController titleController;
  late TextEditingController durationController;

  XFile? cover;
  File? audio;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.song.title);
    durationController = TextEditingController(text: widget.song.duration.toString());
  }

  void pilihCover() async {
    cover = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  void pilihAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      audio = File(result.files.single.path!);
      setState(() {});
    }
  }

  void _update(BuildContext context) async {
    if (titleController.text.isNotEmpty &&
        durationController.text.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await apiService.updateSong(
        widget.song.id,
        titleController.text,
        int.parse(durationController.text),
        cover,
        audio,
      );

      Navigator.pop(context);

      if (response['success'] == true) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: "Sukses",
          desc: response['message'],
          btnOkOnPress: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ArtisFooterPage()));
          },
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: "Error",
          desc: response['message'].toString(),
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        title: const Text("Update Music"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔶 Upload Cover
            _buildCoverCard(),

            const SizedBox(height: 20),

            // 🔶 Upload Audio
            _buildAudioCard(),

            const SizedBox(height: 30),

            // 🔶 Form Input
            _buildInputForm(),

            const SizedBox(height: 30),

            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // CARD UNTUK COVER
  // ======================================================
  Widget _buildCoverCard() {
    return InkWell(
      onTap: pilihCover,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              "Upload Cover",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            cover == null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(imageUrl: "http://10.0.2.2:8000/images/${widget.song.cover}", fit: BoxFit.cover, height: 170, errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 80,),),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(cover!.path),
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),

            const SizedBox(height: 10),
            Text(
              "Tap untuk memilih gambar",
              style: TextStyle(color: Colors.orange.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // CARD UNTUK AUDIO
  // ======================================================
  Widget _buildAudioCard() {
    return InkWell(
      onTap: pilihAudio,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.music_note,
                size: 40, color: Colors.orange.shade700),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                audio == null
                    ? widget.song.audio
                    : audio!.path.split('/').last,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 16,
                ),
              ),
            ),

            Icon(Icons.upload, color: Colors.orange.shade600)
          ],
        ),
      ),
    );
  }

  // ======================================================
  // INPUT FORM
  // ======================================================
  Widget _buildInputForm() {
    return Column(
      children: [

        _inputField(
          label: "Judul Music",
          controller: titleController,
          icon: Icons.music_note_outlined,
        ),

        const SizedBox(height: 20),

        _inputField(
          label: "Durasi (detik)",
          controller: durationController,
          icon: Icons.timer,
        ),

      ],
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orange.shade700),
        labelText: label,
        labelStyle: TextStyle(color: Colors.orange.shade600),
        filled: true,
        fillColor: Colors.orange.shade100.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.orange.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
        ),
      ),
    );
  }

  // ======================================================
  // BUTTON SECTION
  // ======================================================
  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArtisFooterPage(),
                )),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.orange.shade600),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text("Cancel",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton(
            onPressed: () => _update(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text("Update"),
          ),
        ),
      ],
    );
  }
}
