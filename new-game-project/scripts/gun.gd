class_name Gun
extends Weapon

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var muzzle_offset: float = 40.0
@export var spread_angle: float = 5.0  # Bullet spread in degrees
@export var recoil_force: float = 50.0
@export var max_ammo: int = 30
@export var reload_time: float = 1.5

var current_ammo: int
var is_reloading: bool = false

@onready var muzzle_flash: Polygon2D

func _ready() -> void:
	super._ready()
	weapon_name = "Gun"
	weapon_type = WeaponType.GUN
	damage = 10
	cooldown = 0.12
	current_ammo = max_ammo

	# Create muzzle flash visual
	muzzle_flash = Polygon2D.new()
	muzzle_flash.name = "MuzzleFlash"
	setup_muzzle_flash()
	muzzle_flash.visible = false
	add_child(muzzle_flash)

func setup_muzzle_flash() -> void:
	# Create a star shape for muzzle flash
	var points = PackedVector2Array()
	var segments = 8
	for i in range(segments):
		var angle = i * TAU / segments
		var radius = 15.0 if i % 2 == 0 else 8.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	muzzle_flash.polygon = points
	muzzle_flash.color = Color(1, 0.8, 0, 0.8)

func perform_attack(direction: Vector2) -> void:
	if is_reloading:
		return

	if current_ammo <= 0:
		reload()
		return

	# Create bullet
	if bullet_scene:
		var bullet = bullet_scene.instantiate()

		# Add spread
		var spread = deg_to_rad(randf_range(-spread_angle, spread_angle))
		var bullet_direction = direction.rotated(spread)

		var spawn_pos = global_position + bullet_direction * muzzle_offset
		bullet.setup(bullet_direction, spawn_pos, damage, player)

		# Set bullet to damage enemies and players
		bullet.add_to_group("player_bullets")
		bullet.collision_layer = 8
		bullet.collision_mask = 1 | 2 | 4  # Players, platforms/walls, enemies

		get_tree().current_scene.add_child(bullet)

	# Show muzzle flash
	_show_muzzle_flash(direction)

	# Apply recoil to player
	if player:
		player.velocity -= direction * recoil_force * 0.5

	current_ammo -= 1
	weapon_fired.emit()

func _show_muzzle_flash(direction: Vector2) -> void:
	muzzle_flash.rotation = direction.angle()
	muzzle_flash.visible = true

	var tween = create_tween()
	muzzle_flash.scale = Vector2(1, 1)
	tween.tween_property(muzzle_flash, "scale", Vector2(0.1, 0.1), 0.05)
	tween.finished.connect(func(): muzzle_flash.visible = false)

func reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return

	is_reloading = true
	can_attack = false

	# Reload timer
	await get_tree().create_timer(reload_time).timeout

	current_ammo = max_ammo
	is_reloading = false
	can_attack = true

func get_ammo_text() -> String:
	return "%d/%d" % [current_ammo, max_ammo]
