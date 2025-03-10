package main

import imgui_rl "lib/imgui/imgui_impl_raylib"
import imgui "lib/imgui"
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
FORCE_MULTIPLIER :: 0.001
COUNT :: 50

DEBUG := true
DEBUG_GRAVITY := true
DEBUG_GRAVITY_ALPHA := 60
DEBUG_VELOCITY := true
DEBUG_VELOCITY_ALPHA := 90
DEBUG_ARROW_HEAD := f32(8)
DEBUG_ARROW_MULTIPLIER := f32(10)

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

// real life
relations := [Color][Color]f32 {
    .red    = {.red =  1, .orange = 1, .green =  1, .blue =  1},
    .orange = {.red =  1, .orange = 1, .green =  1, .blue =  1},
    .green  = {.red =  1, .orange = 1, .green =  1, .blue =  1},
    .blue   = {.red =  1, .orange = 1, .green =  1, .blue =  1},
}

// // separation
// relations := [Color][Color]f32 {
//     .red    = {.red =  1, .orange = -1, .green = -1, .blue = -1},
//     .orange = {.red = -1, .orange =  1, .green = -1, .blue = -1},
//     .green  = {.red = -1, .orange = -1, .green =  1, .blue = -1},
//     .blue   = {.red = -1, .orange = -1, .green = -1, .blue =  1},
// }

// // train
// relations := [Color][Color]f32 {
//     .red    = {.red =  1, .orange =  2, .green = -1, .blue = -2},
//     .orange = {.red = -2, .orange =  1, .green =  2, .blue = -1},
//     .green  = {.red = -1, .orange = -2, .green =  1, .blue =  2},
//     .blue   = {.red =  2, .orange = -1, .green = -2, .blue =  1},
// }

factors := sort([]Factor{
    // {le = RADIUS, factor = -4},
    // {le =   5, factor = 1},
    // {le =   7, factor = 50},
    // {le =  15, factor = 60},
    {le =  20, factor = 200},
    // {le =  30, factor = 45},
    {le =  60, factor = 80},
    {le = 100, factor = 30},
    {le = 150, factor = 10},
    {le = 250, factor = 5},
    {le = 500, factor = 1},
})

SCREEN_CENTER :: vec2{SCREEN_WIDTH/2, SCREEN_HEIGHT/2}

// MAIN
main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Particle Life")
    rl.SetTargetFPS(60)

    imgui.CreateContext(nil)
    defer imgui.DestroyContext(nil)
    imgui_rl.init()
    defer imgui_rl.shutdown()
    imgui_rl.build_font_atlas()

    seed: u64 = rand.uint64()
    // seed: u64 = 14635494763178228967
    fmt.println("seed:", seed)
    rand.reset(seed)

    world := World{
        particles = random_particles(COUNT),
        // particles = {
        //     {id = new_id(), pos = SCREEN_CENTER - {10, 0}, vel = {0, -1}},
        //     {id = new_id(), pos = SCREEN_CENTER + {10, 0}, vel = {0,  1}},
        // },
        factors = factors,
        relations = relations,
    }

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)
        rl.DrawFPS(10, 10)
        imgui_rl.process_events()
        imgui_rl.new_frame()
        imgui.NewFrame()

        check_pause()

        if !paused {
            update(world)
        }
        draw(world)
        draw_ui(&world)

        imgui.Render()
        imgui_rl.render_draw_data(imgui.GetDrawData())
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

        if DEBUG { 
            draw_debug(w, particle) 
        }
    }
}

draw_ui :: proc(w: ^World) {
    context.allocator = context.temp_allocator
    defer free_all()

    {
        imgui.Begin("Debug")
        defer imgui.End()

        imgui.Checkbox("Enabled", &DEBUG)
        imgui.Checkbox("Velocity", &DEBUG_VELOCITY)
        imgui.Checkbox("Gravity", &DEBUG_GRAVITY)
        imgui.SliderFloat("Arrow Size", &DEBUG_ARROW_MULTIPLIER, 0, 50)
    }

    {
        imgui.Begin("Relations")
        defer imgui.End()

        for &row, color_a in w.relations {
            colf_a := imgui.ColorConvertFloat4ToU32(color_u8_to_f32(auto_cast color_values[color_a]))
            imgui.PushStyleColor(.Header, colf_a)

            if imgui.CollapsingHeader(fmt.caprint(color_a)) {
                for &val, color_b in row {
                    colf_b := imgui.ColorConvertFloat4ToU32(color_u8_to_f32(auto_cast color_values[color_b]))
                    imgui.PushStyleColor(.SliderGrab, colf_b)
                    imgui.PushStyleColor(.SliderGrabActive, colf_b)

                    imgui.SliderFloat(fmt.caprint(color_a, "<>", color_b), &val, -5, 5)

                    imgui.PopStyleColor()
                    imgui.PopStyleColor()
                }
            }

            imgui.PopStyleColor()
        }
    }
}

draw_debug :: proc(w: World, p: Particle) {
    if DEBUG_VELOCITY {
        draw_arrow(p.pos, p.pos + (p.vel * DEBUG_ARROW_MULTIPLIER), {255, 255, 255, auto_cast DEBUG_VELOCITY_ALPHA})
    }

    if DEBUG_GRAVITY {
        for f in w.factors {
            rl.DrawCircleLinesV(p.pos, f.le, {255, 255, 255, auto_cast DEBUG_GRAVITY_ALPHA})
        }
    }
}

draw_arrow :: proc(from, to: vec2, color: rl.Color) {
    rl.DrawLineV(from, to, color)

    // go to relative
    rel_to := to - from

    // TODO: decrease ARROW_HEAD if distance is too small
    back := rel_to - (linalg.normalize(rel_to) * DEBUG_ARROW_HEAD)
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
