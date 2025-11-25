<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Song extends Model
{
    protected $table = "song";
    protected $fillable = ['id_user','title','cover','audio','duration','plays_count'];

    //artis
    function user(){
        return $this->belongsTo(User::class,'id_user');
    }

    function favoritedBy(){
        return $this->belongsToMany(User::class,'favorite','song_id','id_user');
    }

    function like(){
        return $this->hasMany(Favorite::class,'song_id');
    }
}
