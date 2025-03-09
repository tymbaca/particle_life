package main

next_id := 0
new_id :: proc() -> int {
    id := next_id
    next_id += 1
    return id
}
