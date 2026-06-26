extends CharacterBody2D

@export var speed := 150
@export var jumpVelocity := -300
@export var gravity := 800
@export var highGravity = 1000
@export var maxFallSpeed := 300

var direction : Vector2i
var dead := false

func _physics_process(delta: float) -> void:
	if dead and position.y > 150:
		get_tree().reload_current_scene()
	
	direction = Vector2(Input.get_axis("Left", "Right"), Input.get_axis("Up", "Down"))
	
	if not dead:
		if is_on_floor():
			velocity.x = 0
			if direction.x:
				velocity.y = -100
		else:
			velocity.x = move_toward(velocity.x, speed * direction.x, speed/3)
	
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y = move_toward(velocity.y, maxFallSpeed, gravity*delta)
			if Input.is_action_just_released("Jump"):
				velocity.y /= 2
		else:
			velocity.y = move_toward(velocity.y, maxFallSpeed, highGravity*delta)
	
	if Input.is_action_just_pressed("Jump") and not dead:
		velocity.y = jumpVelocity
	
	move_and_slide()

func die():
	dead = true
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)
	velocity.y = jumpVelocity
	velocity.x *= -1
	velocity.x += randi_range(-40,40)

func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	die()
