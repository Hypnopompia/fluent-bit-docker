<?php

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    Log::info("Hello World!", ['context' => 'foo']);
    return "Log Saved";
});
