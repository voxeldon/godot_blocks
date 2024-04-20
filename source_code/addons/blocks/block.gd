@tool 
extends Node2D

class_name Block
const _CUBE_16X_16 = preload("res://addons/blocks/tiles/cube_16x16.tscn")
const _CUBE_16X_32 = preload("res://addons/blocks/tiles/cube_16x32.tscn")
const _CUBE_16X_32_FLIP = preload("res://addons/blocks/tiles/cube_16x32_flip.tscn")
const _CUBE_16X_64 = preload("res://addons/blocks/tiles/cube_16x64.tscn")
const _CUBE_16X_64_FLIP = preload("res://addons/blocks/tiles/cube_16x64_flip.tscn")
const _CUBE_32X_32 = preload("res://addons/blocks/tiles/cube_32x32.tscn")
const _CUBE_32X_64 = preload("res://addons/blocks/tiles/cube_32x64.tscn")
const _CUBE_32X_64_FLIP = preload("res://addons/blocks/tiles/cube_32x64_flip.tscn")
const _CUBE_64X_64 = preload("res://addons/blocks/tiles/cube_64x64.tscn")

const _WEDGE_16X_16 = preload("res://addons/blocks/tiles/wedge_16x16.tscn")
const _WEDGE_16X_16_FLIP = preload("res://addons/blocks/tiles/wedge_16x16_flip.tscn")
const _WEDGE_16X_32 = preload("res://addons/blocks/tiles/wedge_16x32.tscn")
const _WEDGE_16X_32_FLIP = preload("res://addons/blocks/tiles/wedge_16x32_flip.tscn")
const _WEDGE_16X_64 = preload("res://addons/blocks/tiles/wedge_16x64.tscn")
const _WEDGE_16X_64_FLIP = preload("res://addons/blocks/tiles/wedge_16x64_flip.tscn")
const _WEDGE_32X_32 = preload("res://addons/blocks/tiles/wedge_32x32.tscn")
const _WEDGE_32X_32_FLIP = preload("res://addons/blocks/tiles/wedge_32x32_flip.tscn")
const _WEDGE_32X_64 = preload("res://addons/blocks/tiles/wedge_32x64.tscn")
const _WEDGE_32X_64_FLIP = preload("res://addons/blocks/tiles/wedge_32x64_flip.tscn")
const _WEDGE_64X_64 = preload("res://addons/blocks/tiles/wedge_64x64.tscn")
const _WEDGE_64X_64_FLIP = preload("res://addons/blocks/tiles/wedge_64x64_flip.tscn")


#connect("block_type_changed", Callable(self, "my_func"))
#signal block_type_changed


## Defines the geometric shape of the block. Allowed types include "Cube" and "Wedge".
@export_enum("Cube", "Wedge") var block_type: String = "Cube":
	set(value):
		if block_type != value:
			#emit_signal("block_type_changed", block_type, value)
			block_type = value; _update_block()

## Indicates whether the block is flipped.
@export var flip: bool = false:
	set(value):if flip != value:flip = value; _update_block()


## Specifies the size of the block using predefined strings. Each string represents width by height in pixels.
@export_enum("16x16", "16x32", "16x64",
			 "32x32", "32x64", "64x64") var dimensions: String = "16x16":
	set(value):if dimensions != value:dimensions = value; _update_block()

## Defines the visual color of the block's mesh in RGBA format.	
@export var mesh_color: Color = Color(0.325, 0.38, 0.384):
	set(value):if mesh_color != value:mesh_color = value; _update_block()
			
@export_group("Behaviour")
## Describes how the block interacts with other objects. Options include "Solid", "Fluid", "Ledge", "Oneway", "Climbable", "Grabbable", and "Passthrough".
@export_enum("Solid", "Fluid", "Ledge", "Oneway", 
			"Climbable", "Grabbable", "ContactFade") var collision_type: String = "Solid":
	set(value):if collision_type != value:collision_type = value; _update_block()

## Affects how movement speed is modified when interacting with the block.
@export var speed_modifier: float = 1.0:
	set(value):if speed_modifier != value:speed_modifier = value; _update_block()

##Adjusts the amount of friction applied by the block.
@export var friction_modifier: float = 1.0:
	set(value):if friction_modifier != value:friction_modifier = value; _update_block()

##Adjusts the delay of when a tile will fade away on contact (REQ: ContactFade).
@export var fade_start_delay: float = 0.5:
	set(value):if fade_start_delay != value:fade_start_delay = value; _update_block()
	
##Adjusts the time it takes a tile to fade away (REQ: ContactFade).
@export var fade_duration: float = 0.5:
	set(value):if fade_duration != value:fade_duration = value; _update_block()
	
##Adjusts the delay of when a faded tile will reset (REQ: ContactFade).
@export var fade_reset_delay: float = 0.5:
	set(value):if fade_reset_delay != value:fade_reset_delay = value; _update_block()

@export_group("Collision Layers")
##Defines physics layers this CollisionObject2D is in.
@export_flags_2d_physics var layer: int = 1:
	set(value):if layer != value:layer = value; _update_block()

##Defines physics layers this CollisionObject2D scans.
@export_flags_2d_physics var mask: int = 1:
	set(value):if mask != value:mask = value; _update_block()

var _block_instance: BlockTile = null
var _block_size: Vector2 = Vector2.ZERO
var _collision_type_id: int = 0

## Enum of Collision Behavioral Types
enum CollisionType {UNKNOWN, SOLID, FLUID, LEDGE, ONEWAY, CLIMBABLE, GRABBABLE, CONTACT_FADE} 
##Array of all existing blocks in scene tree
static var blocks: Array = []

func _enter_tree() -> void:
	for child in get_children():
		if child: remove_child(child)	
	_update_block()
	blocks.append(self)
	
func _exit_tree() -> void:
	blocks.erase(self)

func _instantiate_block(block_scene: PackedScene) -> void:
	_block_instance = block_scene.instantiate()
	add_child(_block_instance)	
	call_deferred("_set_properties")

func _set_properties() -> void:
	_block_instance._mesh_color = mesh_color
	_block_instance._update_color()
	_collision_type_id = BlockDef.convert_collision_type(self)
	_block_instance._update_icon(_collision_type_id)
	_block_instance._update_oneway_collision(_collision_type_id)
	if _collision_type_id == Block.CollisionType.CONTACT_FADE:
		_block_instance._update_contact_fade(_block_size, fade_start_delay, fade_duration, fade_reset_delay)	
	if _collision_type_id == Block.CollisionType.CLIMBABLE:
		_block_instance._update_collision_layers(0, 0)
		z_index = -1	
	else:
		z_index = 0
		_block_instance._update_collision_layers(layer, mask )	

func _update_block() -> void:
	for child in get_children():
		if child: remove_child(child)
	if block_type == "Cube": 
		if dimensions == "16x16":
			_block_size = Vector2(16,16)
			_instantiate_block(_CUBE_16X_16)
		elif dimensions == "16x32":
			if flip:
				_block_size = Vector2(16,32)
				_instantiate_block(_CUBE_16X_32)
			else:
				_block_size = Vector2(32,16)
				_instantiate_block(_CUBE_16X_32_FLIP)
		elif dimensions == "16x64":
			if flip:
				_block_size = Vector2(16,64)
				_instantiate_block(_CUBE_16X_64)
			else:
				_block_size = Vector2(64,16)
				_instantiate_block(_CUBE_16X_64_FLIP)
		elif dimensions == "32x32":
			_block_size = Vector2(32,32)
			_instantiate_block(_CUBE_32X_32)
		elif dimensions == "32x64":
			if flip:
				_block_size = Vector2(32,64)
				_instantiate_block(_CUBE_32X_64)
			else:
				_block_size = Vector2(64,32)
				_instantiate_block(_CUBE_32X_64_FLIP)
		elif dimensions == "64x64":
			_block_size = Vector2(64,64)
			_instantiate_block(_CUBE_64X_64)
	else: 
		if dimensions == "16x16":
			_block_size = Vector2(16,16)
			if !flip:
				_instantiate_block(_WEDGE_16X_16)
			else:
				_instantiate_block(_WEDGE_16X_16_FLIP)
		elif dimensions == "16x32":
			_block_size = Vector2(32,16)
			if !flip:
				_instantiate_block(_WEDGE_16X_32)
			else:
				_instantiate_block(_WEDGE_16X_32_FLIP)
		elif dimensions == "16x64":
			_block_size = Vector2(64,16)
			if !flip:
				_instantiate_block(_WEDGE_16X_64)
			else:
				_instantiate_block(_WEDGE_16X_64_FLIP)
		elif dimensions == "32x32":
			_block_size = Vector2(32,32)
			if !flip:
				_instantiate_block(_WEDGE_32X_32)
			else:
				_instantiate_block(_WEDGE_32X_32_FLIP)
		elif dimensions == "32x64":
			_block_size = Vector2(64,32)
			if !flip:
				_instantiate_block(_WEDGE_32X_64)
			else:
				_instantiate_block(_WEDGE_32X_64_FLIP)
		elif dimensions == "64x64":
			_block_size = Vector2(64,64)
			if !flip:
				_instantiate_block(_WEDGE_64X_64)
			else:
				_instantiate_block(_WEDGE_64X_64_FLIP)

## Determines whether the given node is of type Block.
## Returns `true` if the node exists and is a Block, otherwise returns `false`.
static func is_block(block:Block) -> bool:
	if block and block is Block: return true
	else: return false

##Returns a block instance if the given position falls within any block's boundaries.
## Iterates over a collection of blocks and checks if the position falls within any block's boundaries.
## Returns the Block if found; otherwise, returns `null`.
static func get_block_at_position(get_pos: Vector2) -> Variant:
	for block in blocks:
		var block_position: Vector2 = Vector2(
			block.position.x,
			block.position.y - block._block_size.y
		) 
		var min_pos: Vector2 = block_position
		var max_pos: Vector2 = block_position + block._block_size
		if (
			(get_pos.x >= min_pos.x and get_pos.x <= max_pos.x) and 
			(get_pos.y >= min_pos.y and get_pos.y <= max_pos.y)
		): return block
	return null

## Retrieves the speed modifier from a block if it is a valid Block instance.
## Returns the speed modifier as a float if the block is valid, otherwise returns 0.0.
static func get_speed_modifier(block:Block) -> float:
	if Block.is_block(block): return float(block.speed_modifier)
	else: return float(0.0)

## Retrieves the friction modifier from a block if it is a valid Block instance.
## Returns the friction modifier as a float if the block is valid, otherwise returns 0.0.	
static func get_friction_modifier(block:Block) -> float:
	if Block.is_block(block): return float(block.friction_modifier)
	else: return float(0.0)

## Determines the collision type of a given block.
## Returns the corresponding CollisionType. otherwise returns UNKNOWN
static func get_collision_type(block: Block) -> CollisionType:
	if Block.is_block(block): 
		var place_in_enum: int = block._collision_type_id
		return CollisionType.values()[place_in_enum]
	else:
		return CollisionType.UNKNOWN
