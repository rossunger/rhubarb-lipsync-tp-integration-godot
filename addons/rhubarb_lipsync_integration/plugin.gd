@tool
extends EditorPlugin

#---------------------------------------------------------------------------------------------------------------#
#   Please note that Rhubarb Lipsync is a command line tool by DanielSWolf that this plugin integrates to Godot.
#---------------------------------------------------------------------------------------------------------------#

signal finished_generating_lipsync_data

const FILENAME_SETTINGS :String= "settings.ini"
const IMPORT_LIPSYNC_SCRIPTNAME :String= "Rhubarb Lipsync TPI"

const SpeechRecognizer = {
	pocketSphinx = 'pocketSphinx',
	phonetic = 'phonetic'
}
enum CleanMode {
	Never,
	OpenPlugin,
	ClosePlugin
}

var path_plugin :String= "":
	get = get_pathplugin

var group_plugin :String= "plugin rhubarb_lipsync_integration"

var Settings :Dictionary

var rhubarbTimer :Timer
var timer_remainingcalls :int= 0

var lipsyncImporterPopup :Control



func _enter_tree():
	load_settings()
	
	if !get_tree().has_group(group_plugin):
		add_to_group(group_plugin)
	add_tool_menu_item(IMPORT_LIPSYNC_SCRIPTNAME, _on_importLipsync_Run)
	_do_cleaning_routine(CleanMode.OpenPlugin)

func _do_cleaning_routine(event :int):
	if !Settings.has("output"):
		load_settings()
	if !Settings.output.has("clean_mode"):
		load_settings()
	if !Settings.output.has("path"):
		load_settings()
	
	if Settings.output.clean_mode != event:
		return
	
	
	match event:
		CleanMode.Never:
			return
		CleanMode.OpenPlugin:
#			print('plugin_opened')
			
			_clean_files()
			
			save_settings()
		CleanMode.ClosePlugin:
#			print('plugin_closed')
			
			_clean_files()
			save_settings()
	
func _clean_files():
	var Dir :Directory= Directory.new()
	if !Dir.dir_exists(Settings.output.path):
		save_settings()
		Dir.make_dir(Settings.output.path)
		return
	
	var files :Array
	if Dir.open(Settings.output.path) == OK:
		Dir.list_dir_begin()
		
		var file_path :String= Dir.get_next()
		while file_path != "":
			files.append(file_path)
			file_path = Dir.get_next()
		Dir.list_dir_end()
		
		for i in files.size():
			# Remove lipsync and sliced audio files.
			if files[i].get_extension() == "tsv":
				Dir.remove(files[i])
			elif files[i].get_extension() == "wav":
				if "SLICED" in files[i]:
					Dir.remove(files[i])
	else:
		return
		
	
func _notification(what: int) -> void:
	match what:
		#Called when you quit to Godot Project List or call close project window (doesn't have to be confirmed quit)
		NOTIFICATION_WM_CLOSE_REQUEST:		
			_do_cleaning_routine(CleanMode.ClosePlugin)


func load_settings():
	load_default_settings()
	
	var configFile :ConfigFile= ConfigFile.new()
	var err = configFile.load(self.path_plugin + FILENAME_SETTINGS)
	if err == OK:
		for section in configFile.get_sections():
#			Might be redundant as the default_settings already created the section
#				Settings[section] = {}
			
			for key in configFile.get_section_keys(section):
				Settings[section][key] = configFile.get_value(section, key)
			if Settings[section].size() > configFile.get_section_keys(section).size():
				save_settings()
		
		#Check if Settings file has empty sections
		for section in Settings:
			if !configFile.has_section(section):
				save_settings()
				break
#			for key in Settings[section]:
#				print('settings:',section,':',key)
#				if !configFile.has_section_key(section, )
				
	elif err == ERR_FILE_NOT_FOUND:
#		load_default_settings()
		save_settings()

func get_pathplugin():
	if !is_inside_tree():
		await tree_entered
	var scr :Script= get_script()
	path_plugin = scr.resource_path.get_base_dir()+'/'
	return path_plugin

func load_default_settings(keys :Array = []):
	var _default_settings :Dictionary= {
		'rhubarb_lipsync': {
			'path': "",
			'recognizer': SpeechRecognizer.pocketSphinx
		},
		'output': {
			'path': self.path_plugin+'.temp/',
			'clean_mode': CleanMode.Never
		},
		'file_checks': {
			'timer_max_calls': 200, # 10 min for 3 s.
			'timer_sec': 3
		},
		'file_selection': {
			'file_dialog': "file_selector_preview" #godot #file_selector_preview
		}
	}
#	print('_defaultsettings ',_default_settings['output']['path'])
		
	if keys == null or keys==[]:
		Settings = _default_settings
		return
	else:
		var str_default_settings :String= "_default_settings"
		for section in _default_settings:
			if section == keys[0]:
				if keys.size() == 1:
					return _default_settings[section]
				else:
					for def_key in _default_settings[section]:
						if keys.size() == 2:
							return _default_settings[section][def_key]
						else:
							return
		return

func save_settings():
	var configFile = ConfigFile.new()
	var err = configFile.load(self.path_plugin + FILENAME_SETTINGS)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		for section in Settings:
			for key in Settings[section]:
				configFile.set_value(section, key, Settings[section][key])
	configFile.save(self.path_plugin + FILENAME_SETTINGS)
	

func _on_importLipsync_Run(event = null) -> void:
	lipsyncImporterPopup = load(self.path_plugin + "RhubarbLipsyncImporter/LipsyncImporterPopup.tscn").instantiate()
	add_child(lipsyncImporterPopup)
#	lipsyncImporterPopup.find_node('Panel').rect_position = OS.window_position + OS.window_size*.5 - lipsyncImporterPopup.find_node('Panel').rect_size*.5
	var size = get_viewport().get_visible_rect().size
	lipsyncImporterPopup.find_node('Panel').rect_position = size*.5 - lipsyncImporterPopup.find_node('Panel').rect_size*.5
	lipsyncImporterPopup.pluginInstance = self

func get_plugin_name() -> String:
	return "rhubarb_lipsync_tpi"

#Returns a mouthDB using the mouth library as input.
func get_mouthDB(mouth_library :String) -> Dictionary:
	var f :ConfigFile= ConfigFile.new() 
	var err :int= f.load(self.path_plugin + "mouthshape_libraries.ini")
	
	var _mouthDB :Dictionary = {}
	match err:
		OK:
			if f.has_section(mouth_library):
				if f.has_section_key(mouth_library, "AI"):
					for shape in f.get_section_keys(mouth_library):
						_mouthDB[shape] = f.get_value(mouth_library, shape)
					return _mouthDB
			else:
				return {}
		ERR_FILE_NOT_FOUND:
			return {}
		_:
			return {}
	
	return {}

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		for child in get_children():
			if !child.is_queued_for_deletion():
				child.queue_free()

func _exit_tree():
	remove_tool_menu_item(IMPORT_LIPSYNC_SCRIPTNAME)
	
	_do_cleaning_routine(CleanMode.ClosePlugin)
	save_settings()

#Executes Rhubarb binary from the Settings.rhubarb_lipsync.path filepath.
#The program should generate lipsync externally to the Settings.output.path directory.
func run_rhubarb_lipsync(path_input_audio :String, are_paths_absolute :bool= false, length :float= 0.0): #Signal should send output path to Connect.
	if !Settings.has('rhubarb_lipsync'):
		print('settings dict has no rhubarb_lipsync section.')
		return
	if !Settings.rhubarb_lipsync.has('path'):
		print('settings dict has no rhubarb_lipsync path key or key is invalid filepath.')
		return
	
	var dir:Directory= Directory.new()
	if !dir.dir_exists(Settings.output.path):
		dir.make_dir_recursive(Settings.output.path)
	
	var input_filename = path_input_audio.get_basename().get_file()
	
	var gpath_rhubarb :String= ProjectSettings.globalize_path(Settings.rhubarb_lipsync.path)
	var gpath_input_audio :String= ProjectSettings.globalize_path(path_input_audio)
	var gpath_output_data :String= ProjectSettings.globalize_path(Settings.output.path + input_filename + '.tsv')

	#Seems a bit innaccessible for Linux systems as Godot doesn't start with a Debug Console like in Windows.
	var pid = OS.execute(
		gpath_rhubarb,[
			"-o",
				gpath_output_data,#Output filepath
				gpath_input_audio,#WAV filepath
			"-r", Settings.rhubarb_lipsync.recognizer,#Speech Recognizer
			"-f", "tsv",#File format
			"--extendedShapes", "GHX"#Additional Mouthshapes
		]
	)
	if pid == -1:
		print("Error. Rhubarb binary file didn't execute successfully.")
		return
	
#	Gross and hacky workaround, ideally the progress bar should show in the Editor
#	or at least printed also on the Editor Console.
#	But Godot doesn't seem to have an "process_died(pid)" signal.

	var Dir = Directory.new()
	if Dir.file_exists(gpath_output_data):
		Dir.remove(gpath_output_data)
		#print("File at "+gpath_output_data+" already exists, so it'll be overwritten")
	
	if is_instance_valid(rhubarbTimer):
		rhubarbTimer.queue_free()
	rhubarbTimer = Timer.new()
	get_tree().root.add_child(rhubarbTimer)
	


	var timer_max_calls :int= ceil(length * 0.33 * 2.5) #0.2 = portions of 5sec | 0.33 portions of 3sec
	timer_max_calls = clamp(timer_max_calls, 20, Settings.file_checks.timer_max_calls) #20 calls = 1min | 200 calls = 10 min | 84= 7min
	
	var timer_sec :int= Settings.file_checks.timer_sec # 3 sec default
	print("Rhubarb is generating lipsync... This may take up to a few minutes. (NOT A ESTIMATE) Plugin will wait for max. "+str(timer_sec * timer_max_calls)+" sec. Check Debug Console for Progress or Errors.")
	
	rhubarbTimer.start(timer_sec)
	timer_remainingcalls = timer_max_calls	
	rhubarbTimer.timeout.connect(_on_RhubarbTimer_timeout.bind(gpath_output_data, input_filename, timer_sec, timer_max_calls))
	
	
func _on_RhubarbTimer_timeout(output_filepath :String, input_filename :String, timer_sec :int, timer_max_calls :int= 12):
	timer_remainingcalls -= 1
		
	var Dir :Directory= Directory.new()
	if Dir.file_exists(output_filepath):
		emit_signal("finished_generating_lipsync_data")
		rhubarbTimer.timeout.disconnect(_on_RhubarbTimer_timeout)
		if !rhubarbTimer.is_queued_for_deletion():
			rhubarbTimer.queue_free()
		return
	if timer_remainingcalls <= 0:
		rhubarbTimer.timeout.disconnect(_on_RhubarbTimer_timeout)
		print("Plugin gave up on waiting for Rhubarb to generate file. This could be because there was an error with Rhubarb generating lipsync, but is probably just because it's taking more than the Timer limit ("+str(timer_sec * timer_max_calls)+" seconds)")
		if !rhubarbTimer.is_queued_for_deletion():
			rhubarbTimer.queue_free()
		return
	if !rhubarbTimer.timeout.is_connected(_on_RhubarbTimer_timeout):
		if !rhubarbTimer.is_queued_for_deletion():
			rhubarbTimer.queue_free()
		return
	rhubarbTimer.start(timer_sec)

#Converts a Rhubarb mouthshape (A,B,C) to a Mouthshape Texture
#(It used to convert a rhubarb mouthshape "A" to a prestonblair mouthshape "MBP", but the function changed functionality)
#Maybe rename to remove the "prestonblair" in function name in the future.
func get_prestonblair_mouthtexture(rhubarb_shape :String, mouthDB :Dictionary) -> StreamTexture2D:
	var shape :String
	match rhubarb_shape:
		'A':
			return mouthDB['MBP']
		'B':
			return mouthDB['etc']
		'C':
			return mouthDB['E']
		'D':
			return mouthDB['AI']
		'E':
			return mouthDB['O']
		'F':
			return mouthDB['U']
		'G':
			return mouthDB['FV']
		'H':
			return mouthDB['L']
		'X':
			return mouthDB['rest']
		_:
			return null

#Only execute importing when Rhubarb has finished generating lipsync data.
#Be careful with this one as if the plugin fails to notice the creation of the lipsync output file,
#it can yield forever and cause a memory leak.
func import_deferred_lipsync(
 audiokey :Dictionary,
 extraParams :Array,
# mouthSprite :Sprite,
 audioPlayer,
 animationPlayer :AnimationPlayer,
 anim_name :String,
 mouthDB :Dictionary
 ): #override_region :bool= false
	var mouthSprite
	var mouthAnimSprite
	var mouthAnimSprite_anim :String
	
	for param in extraParams:
		if param is Sprite2D or param is Sprite3D:
			mouthSprite = param
		elif param is AnimatedSprite2D:
			mouthAnimSprite = param
		elif param is String:
			mouthAnimSprite_anim = param
	
	var anim = animationPlayer.get_animation(anim_name)
	await finished_generating_lipsync_data
	if is_instance_valid(mouthSprite):
		import_lipsync(
			anim,
			animationPlayer,
			audiokey,
			audioPlayer,
			mouthDB,
			[mouthSprite]
		)
	elif is_instance_valid(mouthAnimSprite):
		import_lipsync(
			anim,
			animationPlayer,
			audiokey,
			audioPlayer,
			mouthDB,
			[mouthAnimSprite, mouthAnimSprite_anim]
		)
			
	

func import_lipsync(
 anim :Animation,
 animationPlayer :AnimationPlayer,
 audiokey :Dictionary,
 audioPlayer,
 mouthDB :Dictionary,
 extraParams :Array
# mouthSprite :Sprite
 ):
	var mouthSprite 
	var mouthAnimSprite :AnimatedSprite2D
	var mouthAnimSprite_anim :String
	
	for param in extraParams:
		if param is Sprite2D or param is Sprite3D:
			mouthSprite = param
		elif param is AnimatedSprite2D:
			mouthAnimSprite = param
		elif param is String:
			mouthAnimSprite_anim = param
	
	if !is_instance_valid(mouthSprite) && !is_instance_valid(mouthAnimSprite):
		print("Rhubarb Lipsync TPI didn't find a Sprite nor an AnimatedSprite to continue importing lipsync.")
		return
	
	
	var anim_root :Node= animationPlayer.get_node(animationPlayer.root_node)
	
	
	var tr_mouth_anim :int= -1
	var tr_mouth_frame :int= -1
	var tr_mouth_texture :int= -1
	var tr_audio :int= anim.find_track(anim_root.get_path_to(audioPlayer), Animation.TYPE_AUDIO)
	if is_instance_valid(mouthSprite):
		tr_mouth_texture = anim.find_track(str(anim_root.get_path_to(mouthSprite))+':texture', Animation.TYPE_VALUE)
		
		if tr_mouth_texture == -1: #If mouthSprite:texture track doesn't exist, create one.
			tr_mouth_texture = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tr_mouth_texture, str(anim_root.get_path_to(mouthSprite))+':texture')
	elif is_instance_valid(mouthAnimSprite):
		tr_mouth_anim = anim.find_track(str(anim_root.get_path_to(mouthAnimSprite))+':animation', Animation.TYPE_ANIMATION)
		if tr_mouth_anim == -1:
			tr_mouth_anim = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tr_mouth_anim, str(anim_root.get_path_to(mouthAnimSprite))+':animation')
			anim.value_track_set_update_mode(tr_mouth_anim, Animation.UPDATE_DISCRETE)
		tr_mouth_frame = anim.find_track(str(anim_root.get_path_to(mouthAnimSprite))+':frame', Animation.TYPE_VALUE)
		if tr_mouth_frame == -1:
			tr_mouth_frame = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tr_mouth_frame, str(anim_root.get_path_to(mouthAnimSprite))+':frame')
			anim.value_track_set_update_mode(tr_mouth_frame, Animation.UPDATE_DISCRETE)
	
	var lipsync_filepath :String= ""
	if !audiokey.has('sliced_path'):
		lipsync_filepath = Settings.output.path + audiokey.stream.resource_path.get_basename().get_file()+'.tsv'
	else:
		lipsync_filepath = Settings.output.path + audiokey.sliced_path.get_basename().get_file() + '.tsv'
	var f = File.new()
	if !f.file_exists(lipsync_filepath):
		print("Rhubarb Lip Sync TPI Importing tried to start, but lipsync file was not found.")
		return
	print("[Rhubarb Lip Sync TPI] Importing Lip Sync to " + anim.resource_name)
	f.open(lipsync_filepath, f.READ)
	var ls_text :String= f.get_as_text() #lipsync_data
	f.close()
	

	
	var ls_line = ls_text.split("\n")
	
	var lipsync_start_time :float= audiokey.time
	var lipsync_end_time :float= audiokey.time + audiokey.stream.get_length()
	if !audiokey.has('sliced_path'):
		lipsync_start_time -= audiokey.start_offset #audiokey.time - audiokey.start_offset
		lipsync_end_time -= audiokey.start_offset + audiokey.end_offset #audiokey.time + audiokey.stream.get_length() - audiokey.start_offset - audiokey.end_offset
#	print("lipsync offset +",lipsync_start_time," -",lipsync_end_time)
	
	for line in ls_line.size():
		var sample = ls_line[line].split("	", false, 2)
		if sample.size() <= 1:
			break
		
		var cur_time :float= lipsync_start_time + float(str2var(sample[0]))
		
		#If key happens before the audiokey, ignore key.
		if !audiokey.has('sliced_path'):
			if cur_time < lipsync_start_time + audiokey.start_offset:
				continue
		else:
			if cur_time < lipsync_start_time:
				continue
		#If key happens after the audiokey, ignore the rest of the keys.
		if cur_time > lipsync_end_time:
			break
		if is_instance_valid(mouthSprite):
			var mouthshape :StreamTexture2D= get_prestonblair_mouthtexture(sample[1], mouthDB)
			anim.track_insert_key( tr_mouth_texture, lipsync_start_time + float(str2var(sample[0])), mouthshape, 0)
		elif is_instance_valid(mouthAnimSprite):
			if anim.track_find_key(tr_mouth_anim, 0.0) == -1:
				anim.track_insert_key(
						tr_mouth_anim,
						0.0,
						mouthAnimSprite_anim
				)
			
			
			var mouthshape_frame :int= 0
			# In MouthFrames mouthDB is based on ints instead of StreamTextures
			match sample[1]:
				'A':
					mouthshape_frame = mouthDB['MBP']
				'B':
					mouthshape_frame = mouthDB['etc']
				'C':
					mouthshape_frame = mouthDB['E']
				'D':
					mouthshape_frame = mouthDB['AI']
				'E':
					mouthshape_frame = mouthDB['O']
				'F':
					mouthshape_frame = mouthDB['U']
				'G':
					mouthshape_frame = mouthDB['FV']
				'H':
					mouthshape_frame = mouthDB['L']
				'X':
					mouthshape_frame = mouthDB['rest']
				_:
					mouthshape_frame = 0
			
			anim.track_insert_key( tr_mouth_frame, lipsync_start_time + float(str2var(sample[0])),	 mouthshape_frame, 0	)
	
