class_name Hitbox
extends Area2D

signal hit(hurtbox)#告知外界攻击到了谁

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(hurtbox: Hurtbox) -> void:
	print("[Hit] %s => %s" %[owner.name,hurtbox.owner.name])
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
