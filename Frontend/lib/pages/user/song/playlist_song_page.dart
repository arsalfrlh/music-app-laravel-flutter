import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music/models/playlist.dart';
import 'package:music/models/playlist_song.dart';
import 'package:music/models/song.dart';
import 'package:music/services/api_service.dart';

class PlaylistSongPage extends StatefulWidget {
  const PlaylistSongPage({required this.playlist});
  final Playlist playlist;

  @override
  State<PlaylistSongPage> createState() => _PlaylistSongPageState();
}

class _PlaylistSongPageState extends State<PlaylistSongPage> {
  final ApiService apiService = ApiService();
  final AudioPlayer player = AudioPlayer();

  // player state
  Song? currentSong;
  int? currentIndex;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
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
      if (mounted) {
        if (currentIndex != null &&
            currentIndex! < widget.playlist.playlistSong.length - 1) {
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

  Future<void> _playAtIndex(int idx) async {
    if (idx < 0 || idx >= widget.playlist.playlistSong.length) return;
    final song = widget.playlist.playlistSong[idx].song;

    try {
      setState(() {
        currentIndex = idx;
        currentSong = song;
        position = Duration.zero;
        duration = Duration.zero;
        isPlaying = true;
      });

      await player.play(
        UrlSource("http://10.0.2.2:8000/song/${song.audio}"),
      );

      apiService.playSong(song.id);

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
      } else if (widget.playlist.playlistSong.isNotEmpty) {
        await _playAtIndex(0);
      }
    }
  }

  Future<void> _playNext() async {
    if (currentIndex == null) return _playAtIndex(0);
    final next = currentIndex! + 1;
    if (next < widget.playlist.playlistSong.length) await _playAtIndex(next);
  }

  Future<void> _playPrev() async {
    if (currentIndex == null) return;
    final prev = currentIndex! - 1;
    if (prev >= 0) await _playAtIndex(prev);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.playlist.playlistName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade700,
                Colors.orange.shade500,
                Colors.orange.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildPlaylistHeader(),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: widget.playlist.playlistSong.length,
                itemBuilder: (_, index) {
                  final pSong = widget.playlist.playlistSong[index];
                  return _buildSongCard(pSong, index);
                },
              ),
            ),
          ],
        ),
      ),

      bottomSheet: currentSong == null ? null : _buildMiniPlayer(context),
    );
  }

  // -----------------------------------------------------
  // HEADER PLAYLIST
  // -----------------------------------------------------
  Widget _buildPlaylistHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200.withOpacity(.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.queue_music_rounded,
            color: Colors.white,
            size: 50,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              widget.playlist.playlistName,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // SONG CARD LIST
  // -----------------------------------------------------
  Widget _buildSongCard(PlaylistSong pSong, int index) {
    final s = pSong.song;
    return GestureDetector(
      onTap: () => _playAtIndex(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade100.withOpacity(.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: "http://10.0.2.2:8000/images/${s.cover}",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.user.name,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.play_circle_fill_rounded,
              size: 34,
              color: Colors.orange.shade700,
            ),
            SizedBox(width: 10,),
            IconButton(
              onPressed: (){
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.warning,
                  animType: AnimType.bottomSlide,
                  title: "Hapus Lagu?",
                  desc: "Apakah Anda yakin ingin menghapus lagu dari Playlist?",
                  btnOkOnPress: ()async{
                    await ApiService().deletePlaylistSong(pSong.id);
                  },
                  btnOkColor: Colors.orange,
                  btnCancelOnPress: (){},
                  btnCancelColor: Colors.grey
                ).show();
              },
              icon: Icon(Icons.delete, size: 34,),
              color: Colors.orange.shade700,
            )
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // MINI PLAYER BAR KEREN GLOWING
  // -----------------------------------------------------
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
              initialPosition: position,
              initialDuration: duration,
              song: s,
              player: player,
              onClose: () => Navigator.of(context).pop(),
              onSkip: _playNext,
              onPreviuse: _playPrev,
              isPlaying: isPlaying,
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
