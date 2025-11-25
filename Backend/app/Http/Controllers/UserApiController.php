<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserApiController extends Controller
{
    public function update(Request $request){
        $user = $request->user();
        if($request->email == $user->email){
            $validator = Validator::make($request->all(),[
                'name' => 'required',
                'email' => 'required|email',
                'bio' => 'nullable',
                'profile' => 'nullable|image|mimes:png,jpg,jpeg'
            ]);
        }else{
            $validator = Validator::make($request->all(),[
                'name' => 'required',
                'email' => 'required|email|unique:users',
                'bio' => 'nullable',
                'profile' => 'nullable|image|mimes:png,jpg,jpeg'
            ]);
        }

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        if($request->hasFile('profile')){
            if(!is_null($user->profile) && file_exists(public_path('images/'.$user->profile))){
                unlink(public_path('images/'.$user->profile));
            }

            $profile = $request->file('profile');
            $nmprofile = time() . '_' . $profile->getClientOriginalName();
            $profile->move(public_path('images'), $nmprofile);
        }else{
            $nmprofile = $user->profile;
        }

        User::find($user->id)->update([
            'name' => $request->name,
            'email' => $request->email,
            'bio' => $request->bio ?? null,
            'profile' => $nmprofile
        ]);

        return response()->json(['message' => "Profile berhasil di perbaharui", 'success' => true]);
    }
}
