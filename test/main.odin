package main

import "../lib/imgui"
import "core:fmt"
import "core:math/linalg"
import "core:math"

vec2 :: [2]f32

SIZE :: 1

main :: proc() {
	point := vec2{-10, 0}

	back := point - (linalg.normalize(point) * SIZE) // {9,0}
	fmt.println(point, back)

	fmt.println(rotate_by_deg(back, point, 30))
	fmt.println(rotate_by_deg(back, point, -30))
}

rotate_by_deg :: proc(point, origin: vec2, angle_deg: f32) -> vec2 {
	vec := point - origin // {-1, 0}
	fmt.println("vec", vec)

    angle_rad := angle_deg * linalg.RAD_PER_DEG

	rot_matrix := matrix[2, 2]f32{
		math.cos(angle_rad), -math.sin(angle_rad), 
		math.sin(angle_rad),  math.cos(angle_rad), 
	}
    fmt.println("matrix", rot_matrix)

    new_vec := rot_matrix * vec
    fmt.println("new_vec", new_vec)

    return new_vec + origin
}
