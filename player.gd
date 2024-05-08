extends CharacterBody2D

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP
}

const GROUP_STATES := [State.RUNNING,State.IDLE,State.LANDING]
const RUN_SPEED := 150.0
const JUMP_VELOCITY := -320.0
const FLOOR_ACCELERATION := RUN_SPEED/0.2
const AIR_ACCELERATION := RUN_SPEED/0.1
const WALL_JUMP_VELOCITY := Vector2(380,-280.0)

# 获取重力加速度
var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var is_first_tick = false

@onready var graphics: Node2D = $Graphics
@onready var animation_playe: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker : RayCast2D =$Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2

#func _physics_process(delta:float) -> void:
	#var direction =Input.get_axis("move_left","move_right")
#
	#velocity.x = move_toward(velocity.x,direction * RUN_SPEED,FLOOR_ACCELERATION*delta)
	#velocity.y += gravity * delta
	#
	#var can_jump = is_on_floor() or coyote_timer.time_left>0
	#var should_jump =can_jump and jump_request_timer.time_left>0
	#if should_jump:
		#velocity.y = JUMP_VELOCITY
		#coyote_timer.stop()
		#jump_request_timer.stop()
	#if is_on_floor():
		#if is_zero_approx(direction) and velocity.x==0:
			#animation_playe.play("idle")
			#if Input.is_action_pressed("move_squat"):
				#animation_playe.play("squat")
			#if Input.is_action_pressed("move_block"):
				#animation_playe.play("block")
		#else:
			#animation_playe.play("running")
	#elif velocity.y < 0 :
			#animation_playe.play("jump")
	#else :
		#animation_playe.play("fall")
	#if not is_zero_approx(direction):
		#sprite_2d.flip_h = direction < 0
		#
	#var was_on_floor = is_on_floor()
	#move_and_slide()
	#
	#if is_on_floor() != was_on_floor:
		#if was_on_floor and not should_jump:
			#coyote_timer.start()
		#else:
			#coyote_timer.stop()
			
func can_wall_slide() -> bool:
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()


func get_next_state(state: State) -> State:
	var can_jump = is_on_floor() or coyote_timer.time_left>0
	var should_jump =can_jump and jump_request_timer.time_left>0
	if should_jump:
		return State.JUMP
	
	var direction :=Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUNNING
		
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDLE
		
		State.JUMP:
			if velocity.y >=0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if can_wall_slide():
				return State.WALL_SLIDING
		
		State.LANDING:
			if not animation_playe.is_playing():
				return State.IDLE
		
		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0 and not is_first_tick :
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall():
				return State.FALL

		State.WALL_JUMP:
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
			if velocity.y >=0:
				return State.FALL
			
	return state


func transition_state(from: State ,to: State)-> void:
	# print("[%s] %s => %s"%[
	# 	Engine.get_physics_frames(),
	# 	State.keys()[from] if from != -1 else "<START>",
	# 	State.keys()[to],
	# ])#输出状态转化信息

	if from not in GROUP_STATES and to in GROUP_STATES:
		coyote_timer.stop()
	match to:
		State.IDLE:
			animation_playe.play("idle")
		
		State.RUNNING:
			animation_playe.play("running")
		
		State.JUMP:
			animation_playe.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
		
		State.FALL:
			animation_playe.play("fall")
			if from in GROUP_STATES:
				coyote_timer.start()
		
		State.LANDING:
			animation_playe.play("landing")
		
		State.WALL_SLIDING:
			animation_playe.play("wall_sliding")
		
		State.WALL_JUMP:
			animation_playe.play("jump")
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()

	is_first_tick = true

func tick_physics(state: State, delta: float)->void:
	match state:
		State.IDLE:
			move(default_gravity,delta)
		
		State.RUNNING:
			move(default_gravity,delta)
		
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity,delta)
		
		State.FALL:
			move(default_gravity,delta)
		
		State.LANDING:
			stand(default_gravity,delta)
		
		State.WALL_SLIDING:
			move(default_gravity / 3,delta)
			graphics.scale.x = get_wall_normal().x
			
		State.WALL_JUMP:
			if state_machine.states_time < 0.1:#0.1秒内无法再次跳跃
				stand(0.0 if is_first_tick else default_gravity,delta)
				graphics.scale.x = get_wall_normal().x#翻转角色，使角色背对墙壁
			else:
				move(default_gravity,delta)

	is_first_tick = false

func move(gravity: float,delta: float)-> void:
	var direction =Input.get_axis("move_left","move_right")
	#var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x,direction * RUN_SPEED,FLOOR_ACCELERATION*delta) 
	velocity.y += gravity * delta
	
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else +1
		
	move_and_slide()

func stand(gravity : float, delta : float)->void:
	#var acceleration = FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x,0.0,AIR_ACCELERATION*delta)
	velocity.y += gravity * delta

	
	move_and_slide()
