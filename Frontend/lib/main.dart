import 'package:flutter/material.dart';
import 'package:music/pages/artis/main/artis_footer_page.dart';
import 'package:music/pages/auth/login_page.dart';
import 'package:music/pages/user/main/footer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final key = await SharedPreferences.getInstance();
  bool status = key.getBool("statusLogin") ?? false;
  String role = key.getString("role") ?? "";
  runApp(MyApp(status: status, role: role,));
}

class MyApp extends StatelessWidget {
  final String role;
  final bool status;

  const MyApp({required this.role, required this.status});

  Widget getInitialPage() {
    if (!status) {
      return LoginPage();
    }

    switch (role) {
      case "artis":
        return ArtisFooterPage();
      case "user":
        return FooterPage();
      default:
        return LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Musik ku",
      debugShowCheckedModeBanner: false,
      home: getInitialPage(),
    );
  }
}