tool
extends VBoxContainer

export var _temp_texture :StreamTexture
var mouthDB :Dictionary
var mouthIconDB :Dictionary= {}
#var has_mouthDB_loaded :bool= false
#var path_plugin

func reload_mouthshape_textures(library :Dictionary):
	for mouthshape in library:
		mouthDB[mouthshape] = load(library[mouthshape])
		mouthIconDB[mouthshape].textureButton.texture_normal = load(library[mouthshape])

func _enter_tree() -> void:
#	_temp_texture = load(owner.path_plugin+"assets/icons/icon_not.png")#StreamTexture.new()
	mouthDB = {
		'rest': _temp_texture,
		'MBP': _temp_texture,
		'O': _temp_texture,
		'U': _temp_texture,
		'etc': _temp_texture,
		'FV': _temp_texture,
		'E': _temp_texture,
		'L': _temp_texture,
		'AI': _temp_texture
	}

#func _ready() -> void:
#	if !is_inside_tree():
#		yield(self, "tree_entered")
#	yield(get_tree(), "idle_frame")
#	print('owner d',owner.name)
#	print('owner dpathplugin =',owner.path_plugin)
	
#	has_mouthDB_loaded = true
	
	
#	print('mouthDB ', mouthDB)

var fileDialog :FileDialog

##
func _on_MouthIcon_pressed(mouthIcon :VBoxContainer) -> void:
	var button :TextureButton= mouthIcon.textureButton
#	ask_for_filepath(textureButton)
	print('image pressed')
	fileDialog = FileDialog.new()
	fileDialog.connect("popup_hide", self, "_on_FileDialog_popup_hide")
	owner.pluginInstance.add_child(fileDialog)
	fileDialog.mode = fileDialog.MODE_OPEN_FILE
	fileDialog.resizable = true
	fileDialog.rect_min_size = Vector2(400, 300)
	fileDialog.filters = PoolStringArray(['*.png','*.jpg'])
#	fileDialog.access = fileDialog.ACCESS_FILESYSTEM
	fileDialog.popup()
	
	yield(fileDialog, "file_selected")
#	print("file path =", fileDialog.current_path)
	button.texture_normal = load(fileDialog.current_path)
	mouthDB[mouthIcon.mouth_shape] = button.texture_normal
#	print('mouthDB =', mouthDB)

######################



func _on_FileDialog_popup_hide():
	if !fileDialog.is_queued_for_deletion():
		fileDialog.queue_free()
