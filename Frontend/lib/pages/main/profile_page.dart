import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:music/models/user.dart';
import 'package:music/pages/auth/login_page.dart';
import 'package:music/pages/main/update_profile_page.dart';
import 'package:music/services/api_service.dart'; // untuk format tanggal

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService apiService = ApiService();
  User? _user;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  void fetchUser() async {
    User? user = await apiService.currentUser();
    setState(() {
      _user = user;
    });
  }

  void _logout(BuildContext context){
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: "Logout",
      desc: "Apakah Anda yakin ingin Logout?",
      btnOkOnPress: ()async{
        await apiService.logout();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      },
      btnOkColor: Colors.orange,
      btnCancelOnPress: (){},
      btnCancelColor: Colors.green,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
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
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                children: [
                  // Profile Picture
                  ProfilePic(image: _user!.profile),
                  const SizedBox(height: 12),

                  // Nama user
                  Text(
                    _user!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "@${_user!.name.toLowerCase().replaceAll(" ", "_")}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 20),

                  // Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Info(infoKey: "Email", info: _user!.email),
                          const Divider(),
                          Info(
                            infoKey: "Bio",
                            info: _user!.bio != null
                                ? _user!.bio!
                                : "Tidak ada bio",
                          ),
                          const Divider(),
                          Info(
                            infoKey: "Bergabung",
                            info: _user!.createdAt != null
                                ? DateFormat("dd MMM yyyy")
                                    .format(_user!.createdAt!)
                                : "-",
                          ),
                          const Divider(),
                          Info(
                            infoKey: "Terakhir Update",
                            info: _user!.updatedAt != null
                                ? DateFormat("dd MMM yyyy")
                                    .format(_user!.updatedAt!)
                                : "-",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Edit Profile Button
                  SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7643),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateProfilePage(user: _user!))).then((_) => fetchUser());
                      },
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text(
                        "Edit Profile",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  const ProfilePic({
    super.key,
    this.image,
  });

  final String? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7643), Color(0xFFFF9E6D)],
        ),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: image != null
              ? CachedNetworkImage(
                  imageUrl: "http://10.0.2.2:8000/images/$image",
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey),
                )
              : const Icon(Icons.account_circle,
                  size: 100, color: Colors.grey),
        ),
      ),
    );
  }
}

class Info extends StatelessWidget {
  const Info({
    super.key,
    required this.infoKey,
    required this.info,
  });

  final String infoKey, info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            infoKey,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              info,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}