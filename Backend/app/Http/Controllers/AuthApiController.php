<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthApiController extends Controller
{
    public function login(Request $request){
        $validator = Validator::make($request->all(),[
            'email' => 'required|email',
            'password' => 'required'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        if(!User::where('email',$request->email)->exists()){
            return response()->json(['message' => "Email tidak terdaftar di sistem", 'success' => false]);
        }

        $login = [
            'email' => $request->email,
            'password' => $request->password
        ];

        if(Auth::attempt($login)){
            $data = [
                'name' => Auth::user()->name,
                'role' => Auth::user()->role,
                'token' => Auth::user()->createToken('auth-token')->plainTextToken
            ];

            return response()->json(['message' => "Login berhasil", 'success' => true, 'data' => $data]);
        }else{
            return response()->json(['message' => "Password anda salah", 'success' => false]);
        }
    }

    public function register(Request $request){
        $validator = Validator::make($request->all(),[
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required',
            'bio' => 'nullable',
            'profile' => 'nullable|image|mimes:jpg,jpeg,png'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        if($request->hasFile('profile')){
            $profile = $request->file('profile');
            $nmprofile = time() . '_' . $profile->getClientOriginalName();
            $profile->move(public_path('images'), $nmprofile);
        }else{
            $nmprofile = null;
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'user',
            'bio' => $request->bio ?? null,
            'profile' => $nmprofile,
        ]);

        $data = [
            'name' => $user->name,
            'role' => $user->role,
            'token' => $user->createToken('auth-token')->plainTextToken
        ];

        return response()->json(['message' => "Register berhasil", 'success' => true, 'data' => $data]);
    }

    public function logout(Request $request){
        $request->user()->tokens()->delete();
        return response()->json(['message' => "Anda telah logout", 'success' => true]);
    }
}
