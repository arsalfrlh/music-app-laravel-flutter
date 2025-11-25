import 'package:music/models/song.dart';

class PlaylistSong {
  final int id;
  final Song song;

  PlaylistSong({required this.id, required this.song});
  factory PlaylistSong.fromJson(Map<String, dynamic> json){
    return PlaylistSong(
      id: json['id'],
      song: Song.fromJson(json['song'])
    );
  }
}