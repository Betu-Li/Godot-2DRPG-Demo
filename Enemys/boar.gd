extends Enemy

enum State{
	IDLE,
	WALK,
	RUN
}

@onready var wall_check:RayCast2D = $Graphics/WallCheck
@onready var player_check:RayCast2D = $Graphics/PlayerCheck
@onready var floor_check:RayCast2D = $Graphics/FloorCheck
@onready var calm_down_timer:Timer = $CalmDownTimer


func can_see_player() -> bool:#是否看到玩家
	if not player_check.is_colliding():
		return false
	return player_check.get_collider() is Player


func tick_physics(state: State, delta: float) -> void:#物理更新
	match state:
		State.IDLE:
			move(0.0,delta)

		State.WALK:
			move(max_speed/3,delta)

		State.RUN:
			if wall_check.is_colliding() or not floor_check.is_colliding():#碰到墙壁或者没有地板就转向
				direction *= -1
			move(max_speed,delta)
			if can_see_player():#追击玩家
				calm_down_timer.start()#开始冷静时间

func get_next_state(state: State) -> State:#获取下一个状态
	if can_see_player():#玩家在附近就追击
		return State.RUN
	
	match state:
		State.IDLE:
			if state_machine.states_time >2:#静止2秒侯开始走动
				return State.WALK

		State.WALK:
			if wall_check.is_colliding() or not floor_check.is_colliding():#碰到墙壁或者没有地板就转向
				return State.IDLE
		
		State.RUN:
			if calm_down_timer.is_stopped():#冷静时间结束就回到静止状态
				return State.IDLE

	return state

func transition_state(from: State ,to: State)-> void:
	print("[%s] %s => %s"%[
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to],
	])#输出状态转化信息

	match to:
		State.IDLE:
			animation.play("idle")
			if wall_check.is_colliding():#碰到墙壁就转向
				direction *= -1 

		State.WALK:
			animation.play("walk")
			if not floor_check.is_colliding():#没有地板就转向
				direction *= -1
				floor_check.force_raycast_update()#强制更新射线检测
			
		State.RUN:
			animation.play("run")






func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	print("Onch!")
