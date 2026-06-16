extends RefCounted
class_name BoardTile

enum TileType {
	ATTACK,
	HEALTH,
	MONEY,
	ENERGY,
	EXPERIENCE
}

const TYPE_KEYS := {
	TileType.ATTACK: &"attack",
	TileType.HEALTH: &"health",
	TileType.MONEY: &"money",
	TileType.ENERGY: &"energy",
	TileType.EXPERIENCE: &"experience"
}

const TYPE_COLORS := {
	TileType.ATTACK: Color("d94a42"),
	TileType.HEALTH: Color("4fc76a"),
	TileType.MONEY: Color("f2c14e"),
	TileType.ENERGY: Color("3fa7e0"),
	TileType.EXPERIENCE: Color("8e6fd8")
}

var type: TileType = TileType.ATTACK
var enhanced: bool = false


func _init(tile_type: TileType = TileType.ATTACK, is_enhanced: bool = false) -> void:
	type = tile_type
	enhanced = is_enhanced


func copy() -> Variant:
	return get_script().new(type, enhanced)


func type_key() -> StringName:
	return TYPE_KEYS[type]


func color() -> Color:
	var base: Color = TYPE_COLORS[type]
	return base.lightened(0.18) if enhanced else base


func score_value() -> int:
	return 2 if enhanced else 1
