extends HBoxContainer

# Old TOdo
# TODO
# Bytt ut lyden

var heart_full : CompressedTexture2D = preload("res://assets/art/ui/ui_ikon_helse_fylt_tekstur.png")
var heart_empty : CompressedTexture2D = preload("res://assets/art/ui/ui_ikon_helse_tomt_tekstur.png")


func set_max_health(max_health):
	if max_health < get_child_count():
		for i in get_child_count() - max_health:
			get_child(-1).free()
	else:
		for i in max_health - get_child_count():
			var heart := TextureRect.new()
			heart.texture = heart_empty
			heart.stretch_mode = TextureRect.STRETCH_KEEP
			add_child(heart)

func update_health(value):
	for i in get_child_count():
		if value > i:
			get_child(i).texture = heart_full
		else:
			get_child(i).texture = heart_empty

func _on_raskeladden_health_changed(new_health):
	update_health(new_health)
