<?php

use App\Http\Controllers\AuthApiController;
use App\Http\Controllers\MusicApiController;
use App\Http\Controllers\PlaylistApiController;
use App\Http\Controllers\UserApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post("/login",[AuthApiController::class,'login']);
Route::post('/register',[AuthApiController::class,'register']);

Route::middleware(['auth:sanctum','user'])->group(function(){
    Route::get('/song',[MusicApiController::class,'userIndex']);
    Route::get('/song/playlist',[PlaylistApiController::class,'index']);
    Route::post('/song/playlist/create',[PlaylistApiController::class,'create']);
    Route::post('/song/playlist/song/create',[PlaylistApiController::class,'createPlaylistSong']);
    Route::delete('/song/playlist/hapus/{id}',[PlaylistApiController::class,'destroy']);
    Route::delete("/song/playlist/song/delete/{id}",[PlaylistApiController::class,'destroyPlaylistSong']);
    Route::get('/song/search',[MusicApiController::class,'search']);
});

Route::middleware(['auth:sanctum','artis'])->group(function(){
    Route::get("/song/me",[MusicApiController::class,'index']);
    Route::post('/song/create',[MusicApiController::class,'create']);
    Route::post('/song/update',[MusicApiController::class,'update']);
    Route::delete('/song/hapus/{id}',[MusicApiController::class,'destroy']);
    // Route::get('/song/analitic',[MusicApiController::class,'analitic']);
});

Route::middleware('auth:sanctum')->group(function(){
    Route::post('/logout',[AuthApiController::class,'logout']);
    Route::post('/song/play',[MusicApiController::class,'playSong']);
    Route::post('/song/like',[MusicApiController::class,'like']);
    Route::post('/profile/update',[UserApiController::class,'update']);
});