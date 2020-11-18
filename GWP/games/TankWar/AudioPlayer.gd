extends AudioStreamPlayer2D


var audio_pistol_shot = preload("res://audios/gun_revolver_pistol_shot_04.wav")
var audio_explosion = preload("res://audios/explosion_large_07.wav")

func _ready():
	Utility.connect_ex(self, "finished", self, "destroy_self")
	self.stop()

func play_sound(sound_name, _position = null):
	if sound_name == "fire":
		self.stream = audio_pistol_shot
	elif sound_name == "explosion":
		self.stream = audio_explosion
	else:
		printerr("unknown sound: ", sound_name)
		queue_free()
		return

	# If you are using an AudioStreamPlayer3D, then uncomment these lines to set the position.
	#if self is AudioStreamPlayer3D:
	#    if position != null:
	#        self.global_transform.origin = position

	self.play()

func destroy_self():
	self.stop()
	queue_free()
