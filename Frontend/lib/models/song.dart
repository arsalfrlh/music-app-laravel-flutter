import 'package:music/models/user.dart';

class Song {
  final int id;
  final String title;
  final String cover;
  final String audio;
  final int duration;
  int playCount;
  int likeCount;
  bool favorited;
  User user;

  Song({required this.id, required this.title, required this.cover, required this.audio, required this.duration, required this.playCount, required this.likeCount, required this.favorited, required this.user});
  factory Song.fromJson(Map<String, dynamic> json){
    return Song(
      id: json['id'],
      title: json['title'],
      cover: json['cover'],
      audio: json['audio'],
      duration: json['duration'],
      playCount: json['plays_count'],
      likeCount: json['like_count'],
      favorited: json['favorited'],
      user: User.fromJson(json['user'])
    );
  }
}