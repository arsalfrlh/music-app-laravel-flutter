import 'package:flutter/material.dart';
import 'package:music/pages/main/profile_page.dart';
import 'package:music/pages/user/main/home_page.dart';
import 'package:music/pages/user/song/playlist_page.dart';
import 'package:music/pages/user/song/search_page.dart';

class FooterPage extends StatefulWidget {
  const FooterPage({super.key});

  @override
  State<FooterPage> createState() => _FooterPageState();
}

class _FooterPageState extends State<FooterPage> {
  int currentIndex = 0;

  final pages = [
    const HomePage(),
    const SearchPage(),
    const PlaylistPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      // FOOTER NAVBAR BARU
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade200.withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,

            currentIndex: currentIndex,
            onTap: (index) => setState(() => currentIndex = index),

            selectedItemColor: Colors.orange.shade800,
            unselectedItemColor: Colors.grey.shade500,

            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
            ),

            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                  size: currentIndex == 0 ? 28 : 24,
                ),
                activeIcon: Icon(
                  Icons.home_rounded,
                  size: 28,
                  color: Colors.orange.shade800,
                ),
                label: "Home",
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.search,
                  size: currentIndex == 1 ? 28 : 24,
                ),
                activeIcon: Icon(
                  Icons.search_rounded,
                  size: 28,
                  color: Colors.orange.shade800,
                ),
                label: "Search",
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.playlist_play_outlined,
                  size: currentIndex == 2 ? 28 : 24,
                ),
                activeIcon: Icon(
                  Icons.playlist_play_rounded,
                  size: 28,
                  color: Colors.orange.shade800,
                ),
                label: "Playlist",
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_outline,
                  size: currentIndex == 3 ? 28 : 24,
                ),
                activeIcon: Icon(
                  Icons.person_rounded,
                  size: 28,
                  color: Colors.orange.shade800,
                ),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
