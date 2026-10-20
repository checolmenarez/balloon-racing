extends Area2D

## NONE keeps the normal race lottery; lessons can request an existing item.
@export var guaranteed_item: BalloonItems.Kind = BalloonItems.Kind.NONE

var combat: ItemCombat
var consumed: bool = false
var _respawn_left: float = 0.0
var _blocked_collectors: Dictionary = {}
var _world_texture: Texture2D
@export_range(0.0, 1.0, 0.05) var halo_opacity: float = 0.18
var _pulse: float = 0.0


func _process(delta: float) -> void:
	_pulse += delta * 3.0
	if visible:
		queue_redraw()


func _ready() -> void:
	_world_texture = load("res://assets/worlds/valle_ventoso/gameplay/signage/item_box_universal.png")
	$Symbol.visible = _world_texture == null
	queue_redraw()
	body_entered.connect(_on_body_entered)
	body_exited.connect(func(body: Node2D) -> void: _blocked_collectors.erase(body))


func _physics_process(delta: float) -> void:
	if combat == null or not combat.enabled or not consumed:
		return
	_respawn_left = maxf(0.0, _respawn_left - delta)
	if _respawn_left > 0.0:
		return
	consumed = false
	show()
	# A rival already inside when the box returns may collect it. The previous
	# collector must leave first, preventing repeated pickups while parked here.
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if consumed or combat == null or not combat.enabled or not body is Balloon or _blocked_collectors.has(body):
		return
	var racer := body as Balloon
	if racer.items.equipped != BalloonItems.Kind.NONE:
		return
	var kind: BalloonItems.Kind = guaranteed_item if guaranteed_item != BalloonItems.Kind.NONE else combat.choose_item(racer)
	if racer.items.collect(kind):
		consumed = true
		_respawn_left = combat.config.box_respawn_time
		_blocked_collectors[racer] = true
		hide()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 31.0 + sin(_pulse) * 3.0, Color(1, 0.88, 0.4, halo_opacity))
	draw_arc(Vector2.ZERO, 28.0 + sin(_pulse) * 2.0, 0, TAU, 32, Color(1, 0.95, 0.65, halo_opacity * 2.0), 2.0, true)
	if _world_texture != null:
		draw_texture_rect(_world_texture, Rect2(-24, -24, 48, 48), false)
		return
	draw_rect(Rect2(-24, -24, 48, 48), Color("554c87"))
	draw_rect(Rect2(-21, -21, 42, 42), Color("ffe484"))
