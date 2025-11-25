import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:music/models/playlist.dart';
import 'package:music/models/song.dart';
import 'package:music/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000/api";

  Future<Map<String, dynamic>> login(String email, String password)async{
    try{
      final response = await http.post(Uri.parse("$baseUrl/login"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": email,
        "password": password
      }));

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        return{
          "success": false,
          "message": json.decode(response.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String bio, XFile? profile)async{
    try{
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/register"));
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      if(bio.isNotEmpty){
        request.fields['bio'] = bio;
      }
      if(profile != null){
        request.files.add(await http.MultipartFile.fromPath("profile", profile.path));
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if(response.statusCode == 200){
        return json.decode(responseData.body);
      }else{
        return{
          "success": false,
          "message": json.decode(responseData.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<User> currentUser()async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/user"),
      headers: {"Authorization": "Bearer $token"});

      if(response.statusCode == 200){
        return User.fromJson(json.decode(response.body));
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<void> logout()async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      await http.post(Uri.parse("$baseUrl/logout"),
      headers: {"Authorization": "Bearer $token"});
    }catch(e){
      throw Exception(e);
    }
    await key.remove("token");
    await key.remove("statusLogin");
    await key.remove("role");
  }

  Future<void> playSong(int songID)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");
    
    try{
      await http.post(Uri.parse("$baseUrl/song/play"),
      headers: {
        "Authorization": 'Bearer $token',
        'Content-Type': 'application/json'},
      body: json.encode({
        "id_song": songID
      }));
    }catch(e){
      throw Exception(e);
    }
  }

  Future<List<Song>> getArtisSong()async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/song/me"),
      headers: {"Authorization": "Bearer $token"});

      if(response.statusCode == 200){
        return(json.decode(response.body)['data'] as List).map((item) => Song.fromJson(item)).toList();
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> addSong(String title, int duration, XFile cover, File audio)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/song/create"));
      request.headers.addAll({"Authorization": "Bearer $token"});
      request.fields['title'] = title;
      request.files.add(await http.MultipartFile.fromPath("cover", cover.path));
      request.files.add(await http.MultipartFile.fromPath("audio", audio.path));
      request.fields['duration'] = duration.toString();

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if(response.statusCode == 200){
        return json.decode(responseData.body);
      }else{
        return{
          "success": false,
          "message": json.decode(responseData.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<Map<String, dynamic>> updateSong(int id, String title, int duration, XFile? cover, File? audio)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/song/update"));
      request.headers.addAll({"Authorization": "Bearer $token"});
      request.fields['id_song'] = id.toString();
      request.fields['title'] = title;
      request.fields['duration'] = duration.toString();
      if(cover != null){
        request.files.add(await http.MultipartFile.fromPath("cover", cover.path));
      }
      if(audio != null){
        request.files.add(await http.MultipartFile.fromPath("audio", audio.path));
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if(response.statusCode == 200){
        return json.decode(responseData.body);
      }else{
        return{
          "success": false,
          "message": json.decode(responseData.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        'message': e
      };
    }
  }

  Future<void> deleteSong(int id)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      await http.delete(Uri.parse("$baseUrl/song/hapus/$id"),
      headers: {"Authorization": "Bearer $token"});
    }catch(e){
      throw Exception(e);
    }
  }

  Future<List<Song>> getAllSong()async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");
    
    try{
      final response = await http.get(Uri.parse("$baseUrl/song"),
      headers: {"Authorization": "Bearer $token"});
      if(response.statusCode == 200){
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => Song.fromJson(item)).toList();
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<List<Playlist>> userPlaylist()async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/song/playlist"),
      headers: {"Authorization": "Bearer $token"});

      if(response.statusCode == 200){
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => Playlist.fromJson(item)).toList();
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<List<Song>> searchSong(String search)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/song/search?search=$search"),
      headers: {"Authorization": "Bearer $token"});

      if(response.statusCode == 200){
        return (json.decode(response.body)['data'] as List).map((item) => Song.fromJson(item)).toList();
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> addPlaylist(String namaPlaylis)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.post(Uri.parse("$baseUrl/song/playlist/create"),
      headers: {
        "Authorization": "Bearer $token",
        'Content-Type': 'application/json'
      },
      body: json.encode({
        "nama_playlist": namaPlaylis
      }));

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        return{
          "success": false,
          'message': json.decode(response.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<Map<String, dynamic>> addPlaylistSong(int playlistID, int songID)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.post(Uri.parse("$baseUrl/song/playlist/song/create"),
      headers: {
        "Authorization": "Bearer $token",
        'Content-Type': 'application/json'
      },
      body: json.encode({
        "id_playlist": playlistID,
        "id_song": songID,
      }));

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        return{
          "success": false,
          'message': json.decode(response.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<void> deletePlaylist(int id)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      await http.delete(Uri.parse("$baseUrl/song/playlist/hapus/$id"),
      headers: {"Authorization": "Bearer $token"});
    }catch(e){
      throw Exception(e);
    }
  }

  Future<void> deletePlaylistSong(int id)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      await http.delete(Uri.parse("$baseUrl/song/playlist/song/delete/$id"),
      headers: {
        "Authorization": "Bearer $token"
      });
    }catch(e){
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> likeSong(int songID)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.post(Uri.parse("$baseUrl/song/like"),
      headers: {
        "Authorization": "Bearer $token",
        'Content-Type': 'application/json'
      },
      body: json.encode({
        "id_song": songID
      }));

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        return{
          "success": false,
          "message": json.decode(response.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile(User user, XFile? profile)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/profile/update"));
      request.headers.addAll({"Authorization": "Bearer $token"});
      request.fields['name'] = user.name;
      request.fields['email'] = user.email;
      request.fields['bio'] = user.bio ?? "";
      if(profile != null){
        request.files.add(await http.MultipartFile.fromPath("profile", profile.path));
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if(response.statusCode == 200){
        return json.decode(responseData.body);
      }else{
        return{
          "success": false,
          "message": json.decode(responseData.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        'message': e
      };
    }
  }
}