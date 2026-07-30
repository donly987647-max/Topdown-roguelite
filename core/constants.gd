class_name GameConstants
extends RefCounted

const TILE_SIZE := 32
const TEST_ROOM_TILES := Vector2i(20, 12)
const TEST_ROOM_SIZE := Vector2(TEST_ROOM_TILES * TILE_SIZE)

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PLAYER_PROJECTILE := 8
const LAYER_ENEMY_PROJECTILE := 16
const LAYER_HAZARD := 32
