<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::create([
            'name' => "One Directory",
            "email" => "onedirection@gmail.com",
            'password' => Hash::make(123),
            'bio' => "Making new Song for change the world",
            'profile' => "one.jpg"
        ]);
        
        User::create([
            'name' => "NCS",
            "email" => "ncs@gmail.com",
            'password' => Hash::make(123),
            'bio' => "More than lovers",
            'profile' => "ncs.jpg"
        ]);

        User::create([
            'name' => "Vicetone",
            "email" => "vicetone@gmail.com",
            'password' => Hash::make(123),
            'bio' => "Something Strange with me",
            'profile' => "vicetone.jpg"
        ]);
    }
}
