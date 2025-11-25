import 'package:flutter/material.dart';
import 'package:music/pages/artis/main/artis_home_page.dart';
import 'package:music/pages/artis/song/analitic_page.dart';
import 'package:music/pages/artis/song/tambah_page.dart';
import 'package:music/pages/main/profile_page.dart';

class ArtisFooterPage extends StatefulWidget {
  const ArtisFooterPage({super.key});

  @override
  State<ArtisFooterPage> createState() => _ArtisFooterPageState();
}

class _ArtisFooterPageState extends State<ArtisFooterPage> {
  int currentIndex = 0;

  final pages = [
    const ArtisHomePage(),           
    const AnaliticPage(),
    const TambahPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade700,
              Colors.orange.shade500,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),

          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,

            currentIndex: currentIndex,
            onTap: (index) {
              setState(() => currentIndex = index);
            },

            selectedItemColor: Colors.orange.shade700,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),

            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),

            items: [
              BottomNavigationBarItem(
                icon: _navItem(Icons.dashboard_outlined, false),
                activeIcon: _navItem(Icons.dashboard_rounded, true),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: _navItem(Icons.bar_chart_outlined, false),
                activeIcon: _navItem(Icons.bar_chart_rounded, true),
                label: "Analytics",
              ),
              BottomNavigationBarItem(
                icon: _navItem(Icons.upload_outlined, false),
                activeIcon: _navItem(Icons.upload_rounded, true),
                label: "Upload",
              ),
              BottomNavigationBarItem(
                icon: _navItem(Icons.person_outline, false),
                activeIcon: _navItem(Icons.person_rounded, true),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom icon dengan animasi glow untuk item aktif
  Widget _navItem(IconData icon, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? Colors.orange.shade100.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Icon(
        icon,
        size: active ? 28 : 24,
        color: active ? Colors.orange.shade700 : Colors.grey.shade500,
      ),
    );
  }
}
