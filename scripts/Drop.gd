# Drop.gd — Material drop that attracts to player
extends RigidBody2D

const ATTRACT_RADIUS := 140.0
const ATTRACT_FORCE := 350.0
var lifetime: float = 9.0

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var dist := global_position.distance_to(player.global_position)
	
	# Attract toward player when close
	if dist < ATTRACT_RADIUS:
		var dir := (player.global_position - global_position).normalized()
		apply_central_force(dir * ATTRACT_FORCE)
	
	# Pickup
	if dist < 22.0:
		GameManager.player_stats["materials"] += 1
		queue_free()
