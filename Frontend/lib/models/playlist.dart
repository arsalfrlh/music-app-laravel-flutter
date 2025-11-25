import 'package:music/models/playlist_song.dart';
import 'package:music/models/user.dart';

class Playlist{
  final int id;
  final String playlistName;
  final int playlistSongCount;
  final DateTime createAt;
  final User user;
  final List<PlaylistSong> playlistSong;

  Playlist({required this.id, required this.playlistName, required this.playlistSongCount, required this.createAt, required this.user, required this.playlistSong});
  factory Playlist.fromJson(Map<String, dynamic> json){
    return Playlist(
      id: json['id'],
      playlistName: json['playlist_name'],
      playlistSongCount: json['playlist_song_count'],
      createAt: DateTime.parse(json['created_at']),
      user: User.fromJson(json['user']),
      playlistSong: (json['playlist_song'] as List).map((item) => PlaylistSong.fromJson(item)).toList()
    );
  }
}