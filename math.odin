package main

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

rotate_by_deg :: proc(point, origin: vec2, angle_deg: f32) -> vec2 {
    vec := point - origin // {-1, 0}

    angle_rad := angle_deg * linalg.RAD_PER_DEG

    rot_matrix := matrix[2, 2]f32{
        math.cos(angle_rad), -math.sin(angle_rad), 
        math.sin(angle_rad),  math.cos(angle_rad), 
    }

    new_vec := rot_matrix * vec

    return new_vec + origin
}

color_u8_to_f32 :: proc(col: [4]u8) -> [4]f32 {
    colf: [4]f32

    for u, i in col {
        colf[i] = f32(u) / 255
    }

    return colf
}
