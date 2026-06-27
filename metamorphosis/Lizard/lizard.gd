extends CharacterBody2D

@export var speed := 200
@export var jumpVelocity := 280
@export var gravity := 1200
@export var highGravity = 1600
@export var maxFallSpeed := 300

@onready var sprite := $AnimatedSprite2D
@onready var collider := $CollisionShape2D
@onready var hitbox := $Area2D

var direction : Vector2i

var dead := false
var deadTimer := 100

var touchingRight := 0
var touchingLeft := 0

enum States{FALL, LEFT, RIGHT, UP, DOWN}
var state := States.FALL

var jumpBuffer := false
var coyote := 0

var holdTimer = 20

func fall(delta: float):
	sprite.set_rotation_degrees(0)
	sprite.position = Vector2(0,-5)
	sprite.flip_v = false
	collider.set_rotation_degrees(0)
	hitbox.set_rotation_degrees(0)
	
	if velocity.y < 0:
		sprite.play("jump")
		velocity.y = move_toward(velocity.y, maxFallSpeed, gravity*delta)
		if Input.is_action_just_released("Jump"):
			velocity.y /= 2
	else:
		velocity.y = move_toward(velocity.y, maxFallSpeed, highGravity*delta)
		sprite.play("fall")
	
	if velocity.x < 0:
		sprite.flip_h = false
	if velocity.x > 0:
		sprite.flip_h = true
	
	if not dead:
		velocity.x = move_toward(velocity.x, speed*direction.x, speed/5)
		if coyote > 0 and jumpBuffer:
			velocity.y = -jumpVelocity
			jumpBuffer = false
	
	if is_on_floor():
		state = States.DOWN
	if is_on_ceiling():
		state = States.UP
		velocity.y = -200
	coyote -= 1

func left(delta: float):
	if not is_on_wall():
		state = States.FALL
		velocity.y = 0
		return
	
	sprite.set_rotation_degrees(90)
	sprite.position = Vector2(5,0)
	sprite.flip_v = false
	collider.set_rotation_degrees(90)
	hitbox.set_rotation_degrees(90)
	velocity.y = move_toward(velocity.y, speed*direction.y, speed/3)
	velocity.x = -40
	
	if velocity.y < 0:
		sprite.flip_h = false
		sprite.play("walk")
	else: 
		if velocity.y > 0:
			sprite.flip_h = true
			sprite.play("walk")
		else:
			sprite.play("idle")
	
	if jumpBuffer and not dead:
		velocity = Vector2(jumpVelocity, -jumpVelocity)
		jumpBuffer = false
		state = States.FALL

func right(delta: float):
	if not is_on_wall():
		state = States.FALL
		velocity.y = 0
		return
	
	sprite.set_rotation_degrees(90)
	sprite.position = Vector2(-5,0)
	sprite.flip_v = true
	collider.set_rotation_degrees(270)
	hitbox.set_rotation_degrees(270)
	velocity.y = move_toward(velocity.y, speed*direction.y, speed/3)
	velocity.x = 40
	
	if velocity.y < 0:
		sprite.flip_h = false
		sprite.play("walk")
	else: 
		if velocity.y > 0:
			sprite.flip_h = true
			sprite.play("walk")
		else:
			sprite.play("idle")
	
	if jumpBuffer and not dead:
		velocity = Vector2(-jumpVelocity, -jumpVelocity)
		jumpBuffer = false
		state = States.FALL

func up(delta: float):
	sprite.set_rotation_degrees(0)
	sprite.position = Vector2(0,5)
	sprite.flip_v = true
	collider.set_rotation_degrees(0)
	hitbox.set_rotation_degrees(0)
	velocity.x = move_toward(velocity.x, speed*direction.x, speed/3)
	
	if velocity.x < 0:
		sprite.flip_h = false
		sprite.play("walk")
	else: 
		if velocity.x > 0:
			sprite.flip_h = true
			sprite.play("walk")
		else:
			sprite.play("idle")
	
	if jumpBuffer and not dead:
		velocity.y = jumpVelocity - 120
		jumpBuffer = false
	
	if not is_on_ceiling():
		velocity.y = move_toward(velocity.y, maxFallSpeed, gravity * delta)
		if velocity.y >= 0:
			state = States.FALL

func down(delta: float):
	sprite.set_rotation_degrees(0)
	sprite.position = Vector2(0,-5)
	sprite.flip_v = false
	collider.set_rotation_degrees(0)
	hitbox.set_rotation_degrees(0)
	velocity.x = move_toward(velocity.x, speed*direction.x, speed/3)
	
	if velocity.x < 0:
		sprite.flip_h = false
		sprite.play("walk")
	else: 
		if velocity.x > 0:
			sprite.flip_h = true
			sprite.play("walk")
		else:
			sprite.play("idle")
	
	if jumpBuffer and not dead:
		velocity.y = -jumpVelocity
		jumpBuffer = false
	
	if not is_on_floor():
		state = States.FALL
		coyote = 6

func _physics_process(delta: float) -> void:
	if holdTimer != 0:
		holdTimer -= 1
		return
	
	direction = Vector2(Input.get_axis("Left", "Right"), Input.get_axis("Up", "Down"))
	
	if Input.is_action_just_pressed("Jump"):
		jumpBuffer = true
	if Input.is_action_just_released("Jump"):
		jumpBuffer = false
	if dead:
		direction = Vector2(0,0)
		deadTimer -= 1
	if position.y > 150 or not deadTimer or Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	
	match state:
		States.FALL:
			fall(delta)
		States.LEFT:
			left(delta)
		States.RIGHT:
			right(delta)
		States.UP:
			up(delta)
		States.DOWN:
			down(delta)
	
	if dead:
		state = States.FALL
	else: 
		if is_on_floor() and velocity.y > 0:
			state = States.DOWN
		else: 
			if touchingLeft and velocity.x < 0 and state != States.LEFT:
				position.x -= 4
				state = States.LEFT
				velocity.y /= 2
			else: 
				if touchingRight and velocity.x > 0 and state != States.RIGHT:
					state = States.RIGHT
					position.x += 4
					velocity.y /= 2
				else:
					if is_on_ceiling() and velocity.y < 0:
						state = States.UP
						velocity.y = -200
						collider.set_rotation_degrees(0)
	
	move_and_slide()
	print(state)
	print(touchingLeft)
	print(touchingRight)

func die():
	if not dead:
		dead = true
		set_collision_layer_value(1, false)
		set_collision_mask_value(2, false)
		velocity.y = -jumpVelocity
		velocity.x *= -1
		velocity.x += randi_range(-80,80)

func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	die()

func _on_left_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	touchingLeft += 1
	print("touching left")

func _on_left_area_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	touchingLeft -= 1
	if touchingLeft < 0:
		touchingLeft = 0
	print("not touching left")

func _on_right_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	touchingRight += 1
	print("touching right")

func _on_right_area_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	touchingRight -= 1
	if touchingRight < 0:
		touchingRight = 0
	print("not touching right")
