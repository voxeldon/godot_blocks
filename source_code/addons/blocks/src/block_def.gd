class_name BlockDef

#enum CollisionType {SOLID, FLUID, LEDGE, ONEWAY, CLIMBABLE, GRABBABLE, PASSTHROUGH} 

static func convert_collision_type(instance: Block) -> int:
	return parse_enum(instance.collision_type)

static func parse_enum(collision_type: String) -> int:
	var _type_id: int = 0
	if   collision_type == "Solid"       :_type_id = 1
	elif collision_type == "Fluid"       :_type_id = 2
	elif collision_type == "Ledge"       :_type_id = 3
	elif collision_type == "Oneway"      :_type_id = 4
	elif collision_type == "Climbable"   :_type_id = 5
	elif collision_type == "Grabbable"   :_type_id = 6
	elif collision_type == "ContactFade" :_type_id = 7
	else: _type_id = 0 #Unknown
	return _type_id

static func get_collider(instance: BlockTile) -> Variant:
	for child in instance.get_children():
		if child is StaticBody2D:
			var gran_child = child.get_child(0)
			if (
				gran_child is CollisionShape2D or 
				gran_child is CollisionPolygon2D
			):
				return gran_child
	return null

static func generate_block_area(size: Vector2) -> Area2D:
	var area2D: Area2D = Area2D.new()
	var collision2D: CollisionShape2D = CollisionShape2D.new()
	var collision_rect:RectangleShape2D = RectangleShape2D.new()
	collision_rect.size = Vector2(size.x - 2, (size.y))
	collision2D.shape = collision_rect
	area2D.add_child(collision2D)
	return area2D
