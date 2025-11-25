<?php

namespace App\Http\Controllers;

use App\Models\Favorite;
use App\Models\Song;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class MusicApiController extends Controller
{
    public function index(Request $request){
        $user = $request->user();
        $data = Song::with(['user', 'favoritedBy' => function($query) use ($user){
            $query->where('users.id', $user->id);
        }])->withCount('like')->where('id_user', $user->id)->get()->map(function($song){
            $song->favorited = $song->favoritedBy->isNotEmpty();
            unset($song->favoritedBy);
            return $song;
        });
        return response()->json(['message' => "Menampilkan semua lagu anda", 'success' => true, 'data' => $data]);
    }

    public function create(Request $request){
        $validator = Validator::make($request->all(),[
            'title' => 'required',
            'cover' => 'required|image|mimes:png,jpg,jpeg',
            'audio' => 'required|file',
            'duration' => 'required|numeric'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        if($request->hasFile('cover')){
            $cover = $request->file('cover');
            $nmcover = time() . '_' . $cover->getClientOriginalName();
            $cover->move(public_path('images'), $nmcover);
        }else{
            $nmcover = null;
        }

        if($request->hasFile('audio')){
            $audio = $request->file('audio');
            $nmaudio = time() . '_' . $audio->getClientOriginalName();
            $audio->move(public_path('song'), $nmaudio);
        }else{
            $nmaudio = null;
        }

        $user = $request->user();
        Song::create([
            'id_user' => $user->id,
            'title' => $request->title,
            'cover' => $nmcover,
            'audio' => $nmaudio,
            'duration' => $request->duration
        ]);

        return response()->json(['message' => "Berhasil menambahkan Audio", 'success' => true]);
    }

    public function update(Request $request){
        $validator = Validator::make($request->all(),[
            'id_song' => 'required|numeric',
            'title' => 'required',
            'cover' => 'nullable|image|mimes:png,jpg,jpeg',
            'audio' => 'nullable|file',
            'duration' => 'required|numeric'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $song = Song::find($request->id_song);
        if($request->hasFile('cover')){
            if(file_exists(public_path('images/'.$song->cover))){
                unlink(public_path('images/'.$song->cover));
            }
            $cover = $request->file('cover');
            $nmcover = time() . '_' . $cover->getClientOriginalName();
            $cover->move(public_path('images'), $nmcover);
        }else{
            $nmcover = $song->cover;
        }

        if($request->hasFile('audio')){
            if(file_exists(public_path('images/'.$song->cover))){
                unlink(public_path('song/'.$song->audio));
            }
            $audio = $request->file('audio');
            $nmaudio = time() . '_' . $audio->getClientOriginalName();
            $audio->move(public_path('song'),$nmaudio);
        }else{
            $nmaudio = $song->audio;
        }

        $song->update([
            'title' => $request->title,
            'cover' => $nmcover,
            'audio' => $nmaudio,
            'duration' => $request->duration
        ]);

        return response()->json(['message' => "Berhasil mengupdate Music", 'success' => true]);
    }

    public function destroy($id){
        $song = Song::find($id);
        if(file_exists(public_path('images/'.$song->cover))){
            unlink(public_path('images/'.$song->cover));
        }

        if(file_exists(public_path('song/'.$song->audio))){
            unlink(public_path('song/'.$song->audio));
        }

        $song->delete();
        return response()->json(['message' => "Music telah dihapus", 'success' => true]);
    }

    public function playSong(Request $request){
        $validator = Validator::make($request->all(),[
            'id_song' => 'required|numeric'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $song = Song::find($request->id_song);
        $song->plays_count = $song->plays_count + 1;
        $song->save();
        return response()->json(['message' => "Anda memutar music", 'success' => true]);
    }

    // public function analitic(Request $request){
    //     $user = $request->user();
    //     $data = [
    //         'song' => Song::with(['user','favoritedBy' => function($query) use ($user){
    //             $query->where('users.id', $user->id);
    //         }])->withCount('like')->where('id_user', $user->id)->get()->map(function($song){
    //             $song->favorited = $song->favoritedBy->isNotEmpty();
    //             unset($song->favoritedBy);
    //             return $song;
    //         }),
    //         'like' => Favorite::whereHas('song', function($query) use ($user){
    //             $query->where('id_user', $user->id);
    //         })->count()
    //     ];

    //     return response()->json(['message' => "Menampilkan Analityc", 'success' => true, 'data' => $data]);
    // }

    public function userIndex(Request $request){
        $user = $request->user();
        $data = Song::with(['user','favoritedBy' => function($query) use ($user){
            $query->where('users.id', $user->id);
        }])->withCount('like')->inRandomOrder()->take(20)->get()->map(function($song){
            $song->favorited = $song->favoritedBy->isNotEmpty();
            unset($song->favoritedBy);
            return $song;
        });
        return response()->json(['message' => "Menampilkan Music", 'success' => true, 'data' => $data]);
    }

    public function like(Request $request){
        $validator = Validator::make($request->all(),[
            'id_song' => 'required|numeric'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $user = $request->user();
        $like = Favorite::where('id_user', $user->id)->where('song_id', $request->id_song)->exists();
        if($like){
            Favorite::where('id_user', $user->id)->where('song_id', $request->id_song)->delete();
        }else{
            Favorite::create([
                'id_user' => $user->id,
                'song_id' => $request->id_song
            ]);
        }

        return response()->json(['message' => $like ? "Mengahpus Music dari Favorit" : "Menambahkan Music ke Favorit", 'success' => true, 'data' => $like]);
    }

    public function search(Request $request){
        $search = $request->get('search');
        $user = $request->user();
        if(strlen($search)){
            $data = Song::with(['user','favoritedBy' => function($query) use ($user){
                $query->where('users.id', $user->id);
            }])->withCount('like')->where('title','like',"%$search%")->orWhereHas('user', function ($query) use ($search) {
                $query->where('name', $search);
            })->get()->map(function($song){
                $song->favorited = $song->favoritedBy->isNotEmpty();
                unset($song->favoritedBy);
                return $song;
            });
        }else{
            $data = [];
        }

        return response()->json(['message' => "Menampilkan hasil pencarian", 'success' => true, 'data' => $data]);
    }
}
