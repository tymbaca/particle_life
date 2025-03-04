package main

import "lib/ecs"
import "base:intrinsics"
import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:slice"

SCREEN_WIDTH :: 600
SCREEN_HEIGHT :: 400
RADIUS :: 4
BACKGROUND :: rl.BLACK
FORCE_MULTIPLIER :: 0.0000003

DEBUG :: true

World :: struct {
    particles: []Particle,
    factors:   []Factor,
    relations: [Color][Color]f32,
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


// MAIN
main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Particle Life")

    world := World{
        particles = random_particles(10),
        factors = sort([]Factor{
            {le = RADIUS, factor = -4},
            {le =   5, factor = 0},
            {le =  15, factor = 2},
            {le =  40, factor = 5},
            {le = 100, factor = 3},
        }),
        relations = [Color][Color]f32 {
            .red   = {.red = -1, .green =  2, .blue = -1},
            .green = {.red = -2, .green =  0, .blue =  1},
            .blue  = {.red =  2, .green =  3, .blue =  1},
        },
    }

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)

        update(world)
        draw(world)

		rl.EndDrawing()
	}
}

update :: proc(w: World) {
    for this, i in w.particles {
        w.particles[i].pos += w.particles[i].vel
        for another in w.particles {
            if this.id == another.id {continue}

            w.particles[i].vel += force(this, another, w.factors, w.relations)
        }
    }
}

draw :: proc(w: World) {
    for particle in w.particles {
        rl.DrawCircleV(particle.pos, RADIUS, color_values[particle.color])

        when DEBUG { draw_debug(w, particle) }
    }
}

draw_debug :: proc(w: World, p: Particle) {
    for f in w.factors {
        rl.DrawCircleLinesV(p.pos, f.le, {255, 255, 255, 150})
    }
}

force :: proc(from, to: Particle, factors: []Factor, relations: [Color][Color]f32) -> vec2 {
    direction := to.pos - from.pos

    factor: f32 = 0
    for f in factors {
        if linalg.length(direction) <= f.le {
            factor = f.factor
            break
        }
    }
    
    return linalg.normalize0(direction) * factor * relations[from.color][to.color] * FORCE_MULTIPLIER
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

sort :: proc(s: $T/[]$E) -> T {
    slice.sort_by(s, proc(a, b: E) -> bool {return a.le < b.le})
    return s
}
