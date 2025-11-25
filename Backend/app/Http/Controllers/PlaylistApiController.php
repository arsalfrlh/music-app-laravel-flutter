<?php

namespace App\Http\Controllers;

use App\Models\Playlist;
use App\Models\PlaylistSong;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PlaylistApiController extends Controller
{
    public function index(Request $request){
        $user = $request->user();
        $data = Playlist::with(['user','playlistSong.song.user','playlistSong.song' => function($query) use ($user){
            $query->with(['favoritedBy' => function($query) use ($user){
                $query->where('users.id', $user->id);
            }])->withCount('like');
        }])->withCount('playlistSong')->where('id_user', $user->id)->get()->map(function($playlist){
            //kita masuk ke model playlistsong| $playlist itu model Playlist
            $playlist->playlist_song = $playlist->playlistSong->map(function($ps){ //$ps itu sekarang model $playlistsong
            $song = $ps->song; //$song itu berisi model belongsto Song| $song sekarang jadi model song
            $song->favorited = $song->favoritedBy->isNotEmpty(); //cek apakah ada atau kosong
            unset($song->favoritedBy);

            return $ps;
        });
            unset($playlist->playlistSong);
            return $playlist;
        });

        return response()->json(['message' => "Menampilkan PlayList Anda", 'success' => true, 'data' => $data]);
    }

    public function create(Request $request){
        $validator = Validator::make($request->all(),[
            'nama_playlist' => 'required'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $user = $request->user();
        $data = Playlist::create([
            'id_user' => $user->id,
            'playlist_name' => $request->nama_playlist
        ]);

        return response()->json(['message' => "Playlist Berhasil dibuat", 'success' => true, 'data' => $data]);
    }

    public function createPlaylistSong(Request $request){
        $validator = Validator::make($request->all(),[
            'id_playlist' => 'required|numeric',
            'id_song' => 'required|numeric'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        PlaylistSong::create([
            'playlist_id' => $request->id_playlist,
            'song_id' => $request->id_song
        ]);

        return response()->json(['message' => "Lagu berhasil ditaambahkan kedalam playlist", 'success' => true]);
    }

    public function destroy($id){
        PlaylistSong::where('playlist_id', $id)->delete();
        Playlist::find( $id)->delete();
        return response()->json(['message' => "Playlist berhasil di hapus", 'success' => true]);
    }

    public function destroyPlaylistSong($id){
        PlaylistSong::find($id)->delete();
        return response()->json(['message' => "Lagu berhasil di hapus dari playlist", 'success' => true]);
    }
}
