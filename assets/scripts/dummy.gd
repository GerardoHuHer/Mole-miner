extends StaticBody2D

var health = 3

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Check if the thing hitting us is an attack
	if area.name == "PlayerAttackArea":
		take_damage(1)

func take_damage(amount):
	health -= amount
	print("Ouch! Health left: ", health)
	
	# Visual Feedback (Turn red)
	modulate = Color.RED
	
	if health <= 0:
		die()
	else:
		# Reset color after 0.1s
		await get_tree().create_timer(0.1).timeout
		modulate = Color.WHITE

func die():
	queue_free() # This un-instances the node safely
