// artis_home_page.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music/models/song.dart';
import 'package:music/models/user.dart';
import 'package:music/pages/artis/song/update_page.dart';
import 'package:music/pages/auth/login_page.dart';
import 'package:music/services/api_service.dart';

class ArtisHomePage extends StatefulWidget {
  const ArtisHomePage({super.key});

  @override
  State<ArtisHomePage> createState() => _ArtisHomePageState();
}

class _ArtisHomePageState extends State<ArtisHomePage> {
  final ApiService apiService = ApiService();
  List<Song> songList = [];
  bool isLoading = false;

  final AudioPlayer player = AudioPlayer();

  Song? currentSong;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isPlaying = false;
  int? currentIndexSong;

  // keep subscriptions to cancel on dispose
  late final Stream<Duration> _positionStream;
  late final Stream<Duration?> _durationStream;
  late final Stream<PlayerState> _playerStateStream;

  @override
  void initState() {
    super.initState();
    fetchSong();
    _positionStream = player.onPositionChanged;
    _durationStream = player.onDurationChanged;
    _playerStateStream = player.onPlayerStateChanged;
    _listenPlayer();
  }

  void _listenPlayer() {
    _positionStream.listen((pos) {
      if (mounted) setState(() => currentPosition = pos);
    });

    _durationStream.listen((dur) {
      if (dur != null && mounted) setState(() => totalDuration = dur);
    });

    _playerStateStream.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> fetchSong() async {
    setState(() => isLoading = true);
    try {
      songList = await apiService.getArtisSong();
    } catch (e) {
      debugPrint('fetchSong error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
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
            color: Colors.orange.shade200.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // FOTO PROFIL
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage: (user.profile != null)
                ? NetworkImage("http://10.0.2.2:8000/images/${user?.profile}")
                : null,
            child: (user.profile == null)
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),

          const SizedBox(width: 16),
          const SizedBox(width: 16),

          // DATA USER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "-",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.library_music, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Total lagu: ${songList.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TOMBOL Logout
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _startPlay(Song song, int indexSong) async {
    try {
      if (currentSong == null || currentSong!.id != song.id) {
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      }
      setState(() {
        currentSong = song;
        currentIndexSong = indexSong; // FIX
      });

      await player.play(UrlSource("http://10.0.2.2:8000/song/${song.audio}"));

      apiService.playSong(song.id);

      setState(() {
        song.playCount = (song.playCount) + 1;
      });
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  Future<void> _nextSong(Song song) async {
    try {
      if (currentSong == null || currentSong!.id != song.id) {
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      }
      setState(() {
        currentSong = song;
        currentIndexSong = (currentIndexSong! + 1);
      });

      await player.play(UrlSource("http://10.0.2.2:8000/song/${song.audio}"));

      apiService.playSong(song.id);

      setState(() {
        song.playCount = (song.playCount) + 1;
      });
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  Future<void> _reviouseSong(Song song) async {
    try {
      if (currentSong == null || currentSong!.id != song.id) {
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      }
      setState(() {
        currentSong = song;
        currentIndexSong = (currentIndexSong! - 1);
      });

      await player.play(UrlSource("http://10.0.2.2:8000/song/${song.audio}"));

      apiService.playSong(song.id);

      setState(() {
        song.playCount = (song.playCount) + 1;
      });
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await player.pause();
    } else {
      if (currentSong != null) {
        await player.resume();
      }
    }
  }

  Future<void> _seekTo(Duration position) async {
    await player.seek(position);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _logout(BuildContext context){
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: "Logout",
      desc: "Apakah anda yakin ingin logout?",
      btnOkOnPress: ()async{
        await apiService.logout();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      },
      btnOkColor: Colors.orange,
      btnCancelOnPress: (){},
      btnCancelColor: Colors.orange
    ).show();
  }

  void _delete(BuildContext context, int id){
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      dismissOnTouchOutside: false,
      title: "Hapus Music",
      desc: "Apakah Anda yakin?",
      btnOkOnPress: ()async{
        await apiService.deleteSong(id);
        await fetchSong();
      },
      btnOkColor: Colors.orange,
      btnCancelOnPress: (){},
      btnCancelColor: Colors.green
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: Colors.orange,
              onRefresh: fetchSong,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: songList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              _buildUserCard(songList[0].user), // CARD ARTIS
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: _buildSearchBar(),
                              ),
                            ],
                          );
                        }

                        final song = songList[index - 1];
                        return SongCard(
                          song: song,
                          onPlay: () => _startPlay(song, index - 1),
                          onEdit: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UpdatePage(song: song))).then((_) => fetchSong());
                          },
                          onDelete: () => _delete(context, song.id),
                          onToggleFavorite: () {
                            setState(() async{
                              song.favorited = !song.favorited;
                              if (song.favorited) {
                                song.likeCount++;
                              } else {
                                song.likeCount = (song.likeCount - 1).clamp(0, 999999);
                              }
                              final response = await apiService.likeSong(song.id);
                              if(response['success'] == false){
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.error,
                                  animType: AnimType.bottomSlide,
                                  dismissOnTouchOutside: false,
                                  title: "Error",
                                  desc: response['message'].toString(),
                                  btnOkColor: Colors.red
                                ).show();
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            /// MINI PLAYER
            if (currentSong != null) Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) {
                      return FullPlayer(
                        song: currentSong!,
                        player: player,
                        initialPosition: currentPosition,
                        initialDuration: totalDuration,
                        onClose: () {
                          Navigator.of(context).pop();
                        },
                        onSkip: currentIndexSong != null && currentIndexSong! < songList.length - 1
                        ? () => _nextSong(songList[currentIndexSong! + 1])
                        : (){},

                        onPreviuse: currentIndexSong != null && currentIndexSong! > 0
                        ? () => _reviouseSong(songList[currentIndexSong! - 1])
                        : (){},
                      );
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: "http://10.0.2.2:8000/images/${currentSong!.cover}",
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) =>
                              const Icon(Icons.broken_image, size: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong!.title,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentSong!.user.name,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),

                            LinearProgressIndicator(
                              value: (totalDuration.inMilliseconds == 0)
                                  ? 0
                                  : currentPosition.inMilliseconds / totalDuration.inMilliseconds,
                              backgroundColor: Colors.white24,
                              color: Colors.deepOrangeAccent,
                              minHeight: 3,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildSearchBar() {
    return TextFormField(
      autofocus: false,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.orange.withOpacity(0.07),
        prefixIcon: Icon(Icons.search, color: Colors.orange.shade700),
        hintText: "Search songs...",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// SONG CARD
/// -------------------------------------------------------------------------
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const SongCard({
    super.key,
    required this.song,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: "http://10.0.2.2:8000/images/${song.cover}",
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => const Icon(Icons.broken_image, size: 40),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(song.user.name, style: TextStyle(color: Colors.orange.shade800)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      InkWell(
                        onTap: onToggleFavorite,
                        child: Row(
                          children: [
                            Icon(
                              song.favorited ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: song.favorited ? Colors.deepOrange : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(song.likeCount.toString(), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Row(
                        children: [
                          Icon(Icons.play_arrow, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Text(song.playCount.toString(), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 16),

                      Row(
                        children: [
                          const Icon(Icons.timelapse, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("${song.duration}m", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              children: [
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Colors.orange)),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.redAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// FULL PLAYER (BOTTOM SHEET)
/// -------------------------------------------------------------------------
class FullPlayer extends StatefulWidget {
  final Song song;
  final AudioPlayer player;
  final Duration initialPosition;
  final Duration initialDuration;
  final VoidCallback onClose, onSkip, onPreviuse;

  const FullPlayer({
    super.key,
    required this.song,
    required this.player,
    required this.initialPosition,
    required this.initialDuration,
    required this.onClose,
    required this.onSkip,
    required this.onPreviuse
  });

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  late Duration position;
  late Duration duration;
  bool isPlayingLocal = false;

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
      if (mounted) setState(() => isPlayingLocal = s == PlayerState.playing);
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
    if (isPlayingLocal) {
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                  ],
                ),
              ),

              /// COVER ART
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: "http://10.0.2.2:8000/images/${widget.song.cover}",
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const Icon(Icons.broken_image, size: 80),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(widget.song.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.song.user.name, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite,
                            color: widget.song.favorited ? Colors.deepOrange : Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.song.likeCount.toString()),
                        const SizedBox(width: 16),
                        const Icon(Icons.play_arrow, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.song.playCount.toString()),
                      ],
                    ),
                  ],
                ),
              ),

              /// SEEKBAR + CONTROLS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(position), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_format(duration), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),

                    Slider(
                      min: 0,
                      max: 1,
                      value: _progress.clamp(0.0, 1.0),
                      activeColor: Colors.orange,
                      inactiveColor: Colors.orange.withOpacity(0.3),
                      onChanged: (v) => _seek(v),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: widget.onSkip,
                          icon: const Icon(Icons.skip_previous, size: 36),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _toggle,
                          icon: Icon(
                            isPlayingLocal
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 64,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: widget.onPreviuse,
                          icon: const Icon(Icons.skip_next, size: 36),
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
