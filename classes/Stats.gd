class_name Stats
extends Node

@export var max_health: int = 3

@onready var health: int = max_health: #使用@onready，使导出变量max_health的值在health前被初始化
    set(v):#使用set函数，使传入的health的新值在被设置时被限制在0和max_health之间
        v = clampi(v, 0, max_health)
        if health == v:
            return
        health = v