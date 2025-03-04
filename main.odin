package main

import "lib/ecs"
import rl "vendor:raylib"
import "core:math/rand"

SCREEN_WIDTH :: 600
SCREEN_HEIGHT :: 400
RADIUS :: 4
BACKGROUND :: rl.BLACK

World :: struct {
    particles: []Particle,
    factors:   []Factor,
}

Factor :: struct {
    le: f32,
    factor: f32,
}

vec2 :: [2]f32

Particle :: struct {
    id:    int,
	pos:   vec2,
	vel:   vec2,
	color: Color,
}

Color :: enum {
	red,
	// orange,
	// yellow,
	green,
	blue,
	// purple,
}

color_values := [Color]rl.Color{
    .red = rl.RED,
    .green = rl.GREEN,
    .blue = rl.BLUE,
}

relations := [Color][Color]i32 {
	.red   = {.red = -1, .green =  2, .blue = -1},
	.green = {.red = -2, .green =  0, .blue =  1},
	.blue  = {.red =  2, .green =  3, .blue =  1},
}

// MAIN
main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Particle Life")

    world := World{
        particles = random_particles(10),
    }

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)

        draw(world)

		rl.EndDrawing()
	}
}

update :: proc(w: World) {
    for this in w.particles {
        for another in w.particles {
            if this.id == another.id {continue}

            
        }
    }
}

draw :: proc(w: World) {
    for particle in w.particles {
        rl.DrawCircleV(particle.pos, RADIUS, color_values[particle.color])
    }
}

random_particles :: proc(n: int, allocator := context.allocator) -> []Particle {
    partricles := make([]Particle, n)

    for i in 0..<n {
        partricles[i] = Particle{
            id = i,
            pos = random_pos({0, 0}, {SCREEN_WIDTH, SCREEN_HEIGHT}),
            vel = {},
            color = rand.choice_enum(Color),
        }
    }

    return partricles
}

random_pos :: proc(min, max: vec2) -> vec2 {
    x := rand.float32_range(min.x, max.x)
    y := rand.float32_range(min.y, max.y)
    return {x, y}
}
