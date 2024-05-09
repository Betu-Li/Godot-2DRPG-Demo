class_name Player
extends CharacterBody2D

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
}

const GROUP_STATES := [
	State.RUNNING,
	State.IDLE,
	State.LANDING,
	State.ATTACK_1,
	State.ATTACK_2,
	State.ATTACK_3
	]#地面上的状态
const RUN_SPEED := 150.0
const JUMP_VELOCITY := -320.0
const FLOOR_ACCELERATION := RUN_SPEED/0.2
const AIR_ACCELERATION := RUN_SPEED/0.1
const WALL_JUMP_VELOCITY := Vector2(380,-280.0)


var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity") as float # 获取重力加速度
var is_first_tick = false
var is_combo_request := false #记录连击事件是否发生

@export var can_combo :=false #设置一个导出属性，作为动画内的是否可以连击的关键帧

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var attack_request_timer: Timer = $AttackRequestTimer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker : RayCast2D =$Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine

func _unhandled_input(event: InputEvent) -> void:#处理输入事件
	if event.is_action_pressed("jump"):#按下跳跃键
		jump_request_timer.start()#开始计时器
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:#如果跳跃时速度小于跳跃速度的一半，则将速度设置为跳跃速度的一半
			velocity.y = JUMP_VELOCITY / 2

	if event.is_action_pressed("attack") and can_combo:
		is_combo_request = true

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
			#animation_player.play("idle")
			#if Input.is_action_pressed("move_squat"):
				#animation_player.play("squat")
			#if Input.is_action_pressed("move_block"):
				#animation_player.play("block")
		#else:
			#animation_player.play("running")
	#elif velocity.y < 0 :
			#animation_player.play("jump")
	#else :
		#animation_player.play("fall")
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
	
	if state in GROUP_STATES and not is_on_floor():#如果当前处于地面状态且不在地面上，则返回下落状态
		return State.FALL

	var direction :=Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if Input.is_action_pressed("attack"):#按下攻击键
				return State.ATTACK_1
			if not is_still:
				return State.RUNNING
		
		State.RUNNING:
			if Input.is_action_pressed("attack"):#按下攻击键
				return State.ATTACK_1
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
			if not is_still:#如果角色在落地时移动，则返回奔跑状态
				return State.RUNNING
			if not animation_player.is_playing():
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
		
		State.ATTACK_1:
			if not animation_player.is_playing():#动画播放完毕
				return State.ATTACK_2 if is_combo_request else State.IDLE #如果连击事件发生，则返回下一个攻击状态，否则返回空闲状态

		State.ATTACK_2:
			if not animation_player.is_playing():#动画播放完毕
				return State.ATTACK_3 if is_combo_request else State.IDLE #如果连击事件发生，则返回下一个攻击状态，否则返回空闲状态

		State.ATTACK_3:
			if not animation_player.is_playing():#动画播放完毕
				return State.IDLE
			
	return state


func transition_state(from: State ,to: State)-> void:#状态转化播放动画
	# print("[%s] %s => %s"%[
	# 	Engine.get_physics_frames(),
	# 	State.keys()[from] if from != -1 else "<START>",
	# 	State.keys()[to],
	# ])#输出状态转化信息

	if from not in GROUP_STATES and to in GROUP_STATES:
		coyote_timer.stop()
	match to:
		State.IDLE:
			animation_player.play("idle")
		
		State.RUNNING:
			animation_player.play("running")
		
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
		
		State.FALL:
			animation_player.play("fall")
			if from in GROUP_STATES:
				coyote_timer.start()
		
		State.LANDING:
			animation_player.play("landing")
		
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
		
		State.WALL_JUMP:
			animation_player.play("jump")
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()

		State.ATTACK_1:
			animation_player.play("attack_1")
			is_combo_request = false
		
		State.ATTACK_2:
			animation_player.play("attack_2")
			is_combo_request = false
		
		State.ATTACK_3:
			animation_player.play("attack_3")
			is_combo_request = false

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
		
		State.ATTACK_1,State.ATTACK_2,State.ATTACK_3:#三个状态下的攻击逻辑相同，所以用枚举合并处理
			stand(default_gravity,delta)#攻击时不移动

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
