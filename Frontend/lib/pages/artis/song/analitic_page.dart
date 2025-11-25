// lib/pages/home_page_redesigned.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music/models/song.dart';
import 'package:music/models/user.dart';
import 'package:music/pages/auth/login_page.dart';
import 'package:music/services/api_service.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AnaliticPage extends StatefulWidget {
  const AnaliticPage({super.key});

  @override
  State<AnaliticPage> createState() => _AnaliticPageState();
}

/// Redesigned Home Page (Dashboard Premium, Orange theme)
class _AnaliticPageState extends State<AnaliticPage> {
  final ApiService apiService = ApiService();
  final AudioPlayer player = AudioPlayer();

  User? _user;
  List<Song> songList = [];
  bool isLoading = false;

  // player state
  Song? currentSong;
  int? currentIndex; // index in songList
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    player.onDurationChanged.listen((d) {
      if (mounted) setState(() => duration = d);
    });
    player.onPositionChanged.listen((p) {
      if (mounted) setState(() => position = p);
    });
    player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => isPlaying = s == PlayerState.playing);
    });

    player.onPlayerComplete.listen((_) {
      // auto next if available
      if (mounted) {
        if (currentIndex != null && currentIndex! < songList.length - 1) {
          _playAtIndex(currentIndex! + 1);
        } else {
          setState(() {
            isPlaying = false;
            position = Duration.zero;
          });
        }
      }
    });
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    try {
      final u = await apiService.currentUser();
      final songs = await apiService.getArtisSong();
      setState(() {
        _user = u;
        songList = songs;
      });
    } catch (e) {
      debugPrint('init error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _initData();
  }

  Future<void> _playAtIndex(int idx) async {
    if (idx < 0 || idx >= songList.length) return;
    final song = songList[idx];

    try {
      // set current
      setState(() {
        currentIndex = idx;
        currentSong = song;
        position = Duration.zero;
        duration = Duration.zero;
        isPlaying = true;
      });

      // play
      await player.play(UrlSource("http://10.0.2.2:8000/song/${song.audio}"));
      // update server play_count (fire and forget)
      apiService.playSong(song.id);

      // update UI model quickly
      setState(() {
        song.playCount = song.playCount + 1;
      });
    } catch (e) {
      debugPrint('play error: $e');
      setState(() => isPlaying = false);
    }
  }

  Future<void> _togglePlay() async {
    if (isPlaying) {
      await player.pause();
    } else {
      if (currentSong != null) {
        await player.resume();
      } else if (songList.isNotEmpty) {
        await _playAtIndex(0);
      }
    }
  }

  Future<void> _seekTo(double relative) async {
    if (duration.inMilliseconds == 0) return;
    final ms = (duration.inMilliseconds * relative).toInt();
    await player.seek(Duration(milliseconds: ms));
  }

  Future<void> _playNext() async {
    if (currentIndex == null) return _playAtIndex(0);
    final next = currentIndex! + 1;
    if (next < songList.length) await _playAtIndex(next);
  }

  Future<void> _playPrev() async {
    if (currentIndex == null) return;
    final prev = currentIndex! - 1;
    if (prev >= 0) await _playAtIndex(prev);
  }

  void _logout(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: "Logout",
      desc: "Apakah anda yakin ingin logout?",
      btnOkOnPress: () async {
        await apiService.logout();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginPage()));
      },
      btnOkColor: Colors.orange,
      btnCancelOnPress: () {},
      btnCancelColor: Colors.orange,
    ).show();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  // small helpers to compute stats
  int get totalSongs => songList.length;
  int get totalPlays => songList.fold(0, (sum, s) => sum + s.playCount);
  int get totalLikes => songList.fold(0, (sum, s) => sum + s.likeCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: isLoading || _user == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              color: Colors.orange,
              onRefresh: _refresh,
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverToBoxAdapter(child: const SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _buildStatsRow()),
                    SliverToBoxAdapter(child: const SizedBox(height: 18)),
                    SliverToBoxAdapter(child: _buildSectionTitle("Semua Lagu")),
                    SliverToBoxAdapter(child: const SizedBox(height: 8)),
                    SliverToBoxAdapter(child: _buildRecentlyPlayed()),
                    SliverToBoxAdapter(child: const SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
      // mini player
      bottomSheet: currentSong == null ? null : _buildMiniPlayer(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = _user!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade300.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AVATAR
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            foregroundImage: (user.profile != null && user.profile!.isNotEmpty)
                ? NetworkImage("http://10.0.2.2:8000/images/${user.profile}")
                : null,
            child: (user.profile == null || user.profile!.isEmpty)
                ? Icon(Icons.person, size: 40, color: Colors.orange.shade700)
                : null,
          ),

          const SizedBox(width: 18),

          // USER DATA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat datang,",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // TAMPILKAN BIO JIKA ADA
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.bio!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // TOMBOL LOGOUT
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            _statCard("Songs", totalSongs.toString(), Icons.library_music_rounded),
            const SizedBox(width: 12),
            _statCard("Plays", totalPlays.toString(), Icons.play_circle_fill_rounded),
            const SizedBox(width: 12),
            _statCard("Likes", totalLikes.toString(), Icons.favorite_rounded),
        ],
        ),
    );
    }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
            colors: [
                Colors.orange.shade700,
                Colors.orange.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            ),
            boxShadow: [
            BoxShadow(
                color: Colors.orange.shade300.withOpacity(.5),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
            ),
            ],
        ),
        child: Column(
            children: [
            // ICON CIRCLE
            Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.22),
                boxShadow: [
                    BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    ),
                ],
                ),
                child: Icon(
                icon,
                color: Colors.white,
                size: 26,
                ),
            ),

            const SizedBox(height: 12),

            // VALUE
            Text(
                value,
                style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.1,
                ),
            ),

            const SizedBox(height: 4),

            // LABEL
            Text(
                title,
                style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                ),
            ),
            ],
        ),
        ),
    );
    }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TITLE
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
              letterSpacing: 0.5,
            ),
          ),

          // SEE ALL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300, width: 1),
            ),
            child: Text(
              "See All",
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayed() {
    if (songList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade300,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade200.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Center(
            child: Text(
              "Belum ada riwayat putar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: songList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = songList[i];

          return GestureDetector(
            onTap: () => _playAtIndex(
              songList.indexWhere((x) => x.id == s.id),
            ),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.orange.shade500,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade300.withOpacity(0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: "http://10.0.2.2:8000/images/${s.cover}",
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.user.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${s.playCount} Plays",
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.favorite, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${s.likeCount} Like",
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MINI PLAYER bottomSheet
   Widget _buildMiniPlayer(BuildContext context) {
    final s = currentSong!;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return FullPlayer(
              isPlaying: isPlaying,
              initialPosition: position,
              initialDuration: duration,
              song: s,
              player: player,
              onClose: () => Navigator.of(context).pop(),
              onSkip: _playNext,
              onPreviuse: _playPrev,
            );
          },
        );
      },
      child: Container(
        height: 95,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade600.withOpacity(.95),
              Colors.orange.shade400.withOpacity(.95),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade300.withOpacity(.5),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Row(
          children: [
            // COVER
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: "http://10.0.2.2:8000/images/${s.cover}",
                width: 62,
                height: 62,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            // TITLE + ARTIST + PROGRESS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    s.user.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(.8),
                    ),
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ACTION BUTTON
            IconButton(
              onPressed: _togglePlay,
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full Player bottom sheet
class FullPlayer extends StatefulWidget {
  final Song song;
  final AudioPlayer player;
  final Duration initialPosition;
  final Duration initialDuration;
  final VoidCallback onClose, onSkip, onPreviuse;
  bool isPlaying;

  FullPlayer({
    super.key,
    required this.song,
    required this.player,
    required this.initialPosition,
    required this.initialDuration,
    required this.onClose,
    required this.onSkip,
    required this.onPreviuse,
    required this.isPlaying
  });

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  late Duration position;
  late Duration duration;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    duration = widget.initialDuration;

    widget.player.onPositionChanged.listen((p) {
      if (mounted) setState(() => position = p);
    });
    widget.player.onDurationChanged.listen((d) {
      if (d != null && mounted) setState(() => duration = d);
    });
    widget.player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => widget.isPlaying = s == PlayerState.playing);
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds;

  Future<void> _seek(double value) async {
    final newPos = Duration(milliseconds: (duration.inMilliseconds * value).toInt());
    await widget.player.seek(newPos);
  }

  Future<void> _toggle() async {
    if (widget.isPlaying) {
      await widget.player.pause();
    } else {
      await widget.player.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // COVER + TITLE
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl:
                                "http://10.0.2.2:8000/images/${widget.song.cover}",
                            width: MediaQuery.of(context).size.width * 0.78,
                            height: MediaQuery.of(context).size.width * 0.78,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) =>
                                const Icon(Icons.broken_image, size: 80, color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      widget.song.title,
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.song.user.name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite,
                          color: widget.song.favorited ? Colors.redAccent : Colors.white70),
                          onPressed: () async{
                            final response = await ApiService().likeSong(widget.song.id);
                            if(response['success'] == true && response['data'] == false){
                              setState(() {
                                widget.song.favorited = true;
                                widget.song.likeCount += 1;
                              });
                            }else if(response['success'] == true && response['data'] == true){
                              setState(() {
                                widget.song.favorited = false;
                                widget.song.likeCount -= 1;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.song.likeCount.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.play_arrow, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          widget.song.playCount.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SEEKBAR + BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(position),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _format(duration),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white54,
                        thumbColor: Colors.deepOrange,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        min: 0,
                        max: 1,
                        value: _progress.clamp(0.0, 1.0),
                        onChanged: _seek,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: widget.onSkip,
                          icon: const Icon(Icons.skip_previous, size: 38, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: _toggle,
                          child: AnimatedScale(
                            scale: widget.isPlaying ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              widget.isPlaying ? Icons.pause_circle : Icons.play_circle_fill,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          onPressed: widget.onPreviuse,
                          icon: const Icon(Icons.skip_next, size: 38, color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}