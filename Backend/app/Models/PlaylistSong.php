<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlaylistSong extends Model
{
    protected $table = "playlist_song";
    protected $fillable = ['playlist_id','song_id'];

    function song(){
        return $this->belongsTo(Song::class,'song_id');
    }
}
