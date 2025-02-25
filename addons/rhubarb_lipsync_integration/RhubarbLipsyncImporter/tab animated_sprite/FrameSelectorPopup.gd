@tool
extends PopupPanel

signal frame_selected (id)
# PopupPanel that allow user to select the desired frame from an AnimatedSprite
# animation to represent a mouthshape in the output lipsync animation

var animSprite
var anim :String
var frame_id :int

@onready var gridContainer :GridContainer= $ScrollContainer/GridContainer


func begin() -> void:
		
	if !is_instance_valid(animSprite):
		queue_free()
		return
	if !is_instance_valid(animSprite.frames):
		queue_free()
		return
	var spriteFrames :SpriteFrames= animSprite.frames
	
	if !spriteFrames.has_animation(anim):
		queue_free()
		return
	
	if spriteFrames.get_frame_count(anim) == 0:
		queue_free()
		return
	
	for i in spriteFrames.get_frame_count(anim):
		var frameTexture :TextureButton= TextureButton.new()
		frameTexture.texture_normal = spriteFrames.get_frame(anim, i)
#		frameTexture.rect_min_size = Vector2(24,24)
		gridContainer.add_child(frameTexture)
		frameTexture.connect("pressed", _on_FrameTexture_pressed, [i])
	_resize_frames()

func _on_FrameTexture_pressed(id :int):
	emit_signal("frame_selected", id)

func _resize_frames():
	var frame_size :Vector2= gridContainer.get_child(0).rect_size
	
	gridContainer.columns = floor(get_real_size().x / (frame_size.x + 1))
