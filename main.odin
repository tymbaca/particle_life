package main

import "core:testing"
import "core:fmt"
// import "lib/ecs"
import "base:intrinsics"
import rl "vendor:raylib"
import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:slice"
import "base:runtime"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
RADIUS :: 4
BACKGROUND :: rl.BLACK
FORCE_MULTIPLIER :: 0.003
COUNT :: 20

ARROW_HEAD :: 5
ARROW_MULTIPLIER :: 50

DEBUG :: true
DEBUG_GRAVITY :: false
DEBUG_VELOCITY :: true
DEBUG_ALPHA :: 50

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
	orange,
	// yellow,
	green,
	blue,
	// purple,
}

color_values := [Color]rl.Color{
    .red = rl.RED,
    .orange = rl.ORANGE,
    .green = rl.GREEN,
    .blue = rl.BLUE,
}


// MAIN
main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Particle Life")
    rl.SetTargetFPS(60)

    seed: u64 = rand.uint64()
    // seed: u64 = 14635494763178228967
    fmt.println("seed:", seed)
    rand.reset(seed)

    world := World{
        particles = random_particles(COUNT),
        factors = sort([]Factor{
            // {le = RADIUS, factor = -4},
            // {le =   5, factor = 1},
            // {le =   7, factor = 50},
            {le =  15, factor = 50},
            {le =  20, factor = 10},
            {le =  30, factor = 5},
            {le =  60, factor = 1.5},
            // {le = 100, factor = 1},
            {le = 150, factor = 0.1},
        }),
        relations = [Color][Color]f32 {
            .red    = {.red =  1, .orange = 1, .green =  1, .blue =  1},
            .orange = {.red =  1, .orange = 1, .green =  1, .blue =  1},
            .green  = {.red =  1, .orange = 1, .green =  1, .blue =  1},
            .blue   = {.red =  1, .orange = 1, .green =  1, .blue =  1},
        },
    }

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)
        rl.DrawFPS(10, 10)

        check_pause()

        if !paused {
            update(world)
        }
        draw(world)

		rl.EndDrawing()
	}
}

paused := false
check_pause :: proc() {
    if rl.IsKeyPressed(.P) {
        paused = !paused
    }
}

update :: proc(w: World) {
    for this, i in w.particles {
        w.particles[i] = teleport(w.particles[i])
        w.particles[i].pos += w.particles[i].vel

        for another, j in w.particles {
            if this.id == another.id {continue}

            w.particles[i], w.particles[j] = collide(w.particles[i], w.particles[j])

            w.particles[i].vel += force(this, another, w.factors, w.relations)
        }
    }
}

draw :: proc(w: World) {
    if paused {
        rl.DrawText("PAUSED", SCREEN_WIDTH - 50, 10, 10, rl.GRAY)
    }

    for particle in w.particles {
        rl.DrawCircleV(particle.pos, RADIUS, color_values[particle.color])

        when DEBUG { 
            draw_debug(w, particle) 
        }
    }
}

draw_debug :: proc(w: World, p: Particle) {
    color := rl.Color{255, 255, 255, DEBUG_ALPHA}

    when DEBUG_VELOCITY {
        draw_arrow(p.pos, p.pos + (p.vel * ARROW_MULTIPLIER), color)
    }

    when DEBUG_GRAVITY {
        for f in w.factors {
            rl.DrawCircleLinesV(p.pos, f.le, color)
        }
    }
}

draw_arrow :: proc(from, to: vec2, color: rl.Color) {
    rl.DrawLineV(from, to, color)

    // go to relative
    rel_to := to - from

    // TODO: decrease ARROW_HEAD if distance is too small
    back := rel_to - (linalg.normalize(rel_to) * ARROW_HEAD)
    lwing := rotate_by_deg(back, rel_to, 30)
    rwing := rotate_by_deg(back, rel_to, -30)

    // return to global
    lwing += from
    rwing += from

    // debug
    // rl.DrawCircleV(lwing, 2, rl.RED)
    // rl.DrawCircleV(rwing, 2, rl.GREEN)

    rl.DrawTriangle(rwing, to, lwing, color)
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

collide :: proc(this, another: Particle) -> (Particle, Particle) {
    this, another := this, another 

    dist_vec := another.pos - this.pos
    distance := linalg.length(dist_vec)

    intersection := -(distance - RADIUS * 2)

    if intersection <= 0 {
        return this, another
    }

    inter_vec := (dist_vec/distance) * intersection

    this.pos += -inter_vec / 2
    another.pos += inter_vec / 2

    return this, another
}

@(test)
collide_test :: proc(t: ^testing.T) {
    before_a, before_b := Particle{pos = {1,1}}, Particle{pos = {3, 1}}
    after_a, after_b := collide(before_a, before_b)

    testing.expect_value(t, after_a.pos, vec2{-2, 1})
    testing.expect_value(t, after_b.pos, vec2{6, 1})
}

teleport :: proc(p: Particle) -> Particle {
    p := p
    if p.pos.x < 0 {
        p.pos.x = SCREEN_WIDTH
    }
    if p.pos.x > SCREEN_WIDTH {
        p.pos.x = 0
    }
    if p.pos.y < 0 {
        p.pos.y = SCREEN_HEIGHT
    }
    if p.pos.y > SCREEN_HEIGHT {
        p.pos.y = 0
    }

    return p
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
