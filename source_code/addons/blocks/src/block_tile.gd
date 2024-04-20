@tool
extends Node2D
class_name BlockTile
@onready var _mesh_instance: MeshInstance2D = $Mesh

@onready var _static_body: StaticBody2D = $StaticBody

const _LADDER_ICON = preload("res://addons/blocks/utl/ladder_icon.png")

var _collider: Variant = null
var _mesh_color: Color = Color(0.325, 0.38, 0.384)
var _area_2d: Area2D = null
var _fade_start_timer: Timer = null
var _fade_duration_timer: Timer = null
var _fade_reset_timer: Timer = null

func _ready() -> void:
	_collider = BlockDef.get_collider(self)

func _update_color() -> void:
	_mesh_instance.modulate = _mesh_color

func _update_collision_layers(layer_value: Variant, mask_value: Variant) -> void:
	for i in range(1, 33): 
		if layer_value:
			_static_body.set_collision_layer_value(i, (layer_value & (1 << (i - 1))) != 0)
		if mask_value:
			_static_body.set_collision_mask_value(i, (mask_value & (1 << (i - 1))) != 0)

func _disable_all_collision_layers() -> void:
	for i in range(1, 33):  
		_static_body.set_collision_layer_value(i, false)  
		_static_body.set_collision_mask_value(i, false)

func _update_oneway_collision(_collision_type_id: int):
	var is_oneway: bool
	if _collision_type_id == Block.CollisionType.ONEWAY: is_oneway = true
	else: is_oneway = false
	
	if _collider is CollisionShape2D: 
		_collider = _collider as CollisionShape2D
		_collider.one_way_collision = is_oneway
	else:
		_collider = _collider as CollisionPolygon2D
		_collider.one_way_collision = is_oneway
		
func _update_icon(_collision_type_id: int):
	if _collision_type_id == Block.CollisionType.CLIMBABLE:
		_mesh_instance.texture = _LADDER_ICON
	else:
		_mesh_instance.texture = null
		
func _update_contact_fade(size: Vector2, fade_start_delay: float, fade_duration: float, fade_reset_delay: float):
	if _area_2d: return
	_area_2d = BlockDef.generate_block_area(size)
	_area_2d.position = Vector2(size.x / 2, -size.y / 2 - 1)
	
	_fade_start_timer = Timer.new()
	_fade_reset_timer = Timer.new()
	_fade_duration_timer = Timer.new()
	_fade_start_timer.one_shot = true
	_fade_duration_timer.one_shot = true
	_fade_reset_timer.one_shot = true
	_fade_start_timer.wait_time = fade_start_delay
	_fade_duration_timer.wait_time = fade_duration
	_fade_reset_timer.wait_time = fade_reset_delay
		
	add_child(_area_2d)
	_area_2d.show_behind_parent = true
	add_child(_fade_start_timer)
	add_child(_fade_reset_timer)
	add_child(_fade_duration_timer)
		
	_area_2d.connect("body_entered", Callable(self,"_on_fade_start"))
	_fade_start_timer.connect("timeout", Callable(self, "_on_fade_active"))
	_fade_reset_timer.connect("timeout", Callable(self, "_on_fade_reset"))
	_fade_duration_timer.connect("timeout", Callable(self, "_on_fade_ended"))

func _on_fade_start(body):
	if body is CharacterBody2D: 
		_fade_start_timer.start()
		print("_on_fade_start")
		
func _on_fade_active():
	_fade_duration_timer.start()
	print("_on_fade_active")
	
func _on_fade_ended():
	_fade_reset_timer.start()
	print("_on_fade_ended")
	var block: Block = get_parent()
	_disable_all_collision_layers()

func _on_fade_reset():
	print("_on_fade_reset")
	var block: Block = get_parent()
	_update_collision_layers(block.layer, block.mask )

func _process(_delta: float) -> void:
	if !_fade_duration_timer: 
		set_process(false)
		return
	if _fade_duration_timer.time_left > 0:
		var remaining_percentage = _fade_duration_timer.time_left / _fade_duration_timer.wait_time
		var current_value = 100 * remaining_percentage
		modulate.a = current_value / 100.0
	if _fade_reset_timer.is_stopped() and _fade_duration_timer.is_stopped() and modulate.a < 100:
		modulate.a += 0.1

