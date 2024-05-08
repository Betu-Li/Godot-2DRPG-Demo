class_name Enemy
extends CharacterBody2D

#图片面朝方向
enum Direction {
	LEFT = -1,
	RIGHT = +1
}

@export var direction = Direction.LEFT: #图片面朝的方向，默认是左。 “@exprot”是为了在编辑器中可以看到这个变量
	set(v): #direction翻转的同时， 翻转graphics的x轴（左右翻转）
		direction = v
		if not is_node_ready():#@export变量在ready之前被调用，此时graphics（@onready）还没有准备好为空，所以要等到ready之后再调用
			await ready
		graphics.scale.x = -direction #怪物默认朝左边，当只有面朝右边时才翻转

@export var max_speed: float = 180 #速度
@export var acceleration: float = 2000 #加速度

var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity") as float #获取默认加速度

@onready var graphics: Node2D = $Graphics
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine


func move(speed:float,delta:float)->void:#移动函数
	velocity.x = move_toward(velocity.x,speed * direction,acceleration*delta)#速度x方向的移动
	velocity.y += default_gravity  * delta
	
	move_and_slide()
