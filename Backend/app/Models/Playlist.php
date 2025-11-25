<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Playlist extends Model
{
    protected $table = "playlist";
    protected $fillable = ["id_user",'playlist_name'];

    function user(){
        return $this->belongsTo(User::class,'id_user');
    }

    function playlistSong(){
        return $this->hasMany(PlaylistSong::class,'playlist_id');
    }
}
