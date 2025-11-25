<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Favorite extends Model
{
    protected $table = "favorite";
    protected $fillable = ['id_user','song_id'];

    function song(){
        return $this->belongsTo(Song::class,'song_id');
    }
}
