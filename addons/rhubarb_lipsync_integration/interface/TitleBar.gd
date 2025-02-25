@tool
extends HBoxContainer

@export var title_name: String:
	set = _set_title_name
@export var icon_texture: StreamTexture2D:
	set = _set_icon_texture

#Node which will move along with mouse.
@export_node_path var window_path
var windowRect :Control

var offset :Vector2
var moving_panel :bool

var label :Label
var closeButton :TextureButton
var iconRect :TextureRect

func _ready() -> void:
	set_process_input(false)
	moving_panel = false

func _enter_tree() -> void:
	closeButton = $CloseButton
	
	
	if window_path == NodePath():
		if get_tree().edited_scene_root != self:
			window_path = self.get_path_to(owner)
		else:
			return
	windowRect = get_node(window_path)
	if !closeButton.is_connected("pressed", _on_CloseButton_pressed):
		closeButton.connect("pressed", _on_CloseButton_pressed, [owner])
	
	if !is_connected( "mouse_entered", _on_mouse_entered):
		connect( "mouse_entered", _on_mouse_entered)
	if !is_connected( "mouse_exited", _on_mouse_exited):
		connect( "mouse_exited",  _on_mouse_exited)
	
func _set_title_name(value :String):
	if value == null:
		return
	if !is_inside_tree():
		if is_instance_valid(self):
			await tree_entered
		
	
	label = $Label
	
	title_name = value
	label.text = value

func _set_icon_texture(value :StreamTexture2D):
	if !is_inside_tree():
		if is_instance_valid(self):
			await tree_entered
	iconRect = $IconRect
	if value == null:
		iconRect.visible = false
		return
	
	icon_texture = value
	iconRect.texture = value
	if !iconRect.visible:
		iconRect.visible = true
	

func _on_CloseButton_pressed(window :Node) -> void:
#	print('window =',window,' was freed')
	if window.is_queued_for_deletion():
		return
	window.queue_free()

	

func _on_mouse_entered() -> void:
	set_process_input(true)


func _on_mouse_exited() -> void:
	set_process_input(false)



func _input(event: InputEvent) -> void:
	if !(event is InputEventMouse):
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				offset = get_global_mouse_position() - windowRect.rect_position 
				moving_panel = true
	
		if moving_panel:
			if !event.pressed: # mouse button released
				moving_panel = false
		
	if event is InputEventMouse:
		if moving_panel:
			windowRect.rect_position = get_global_mouse_position() - offset

