package main

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(600, 400, "Particle Life")

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)
        rl.EndDrawing()
    }
}
