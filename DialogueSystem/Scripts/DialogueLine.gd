extends Resource
class_name DialogueLine

enum SpeakerEmotion { NEUTRAL, HAPPY, SAD, ANGRY, SURPRISED }

@export var speaker_name: String = ""
@export_multiline var text: String = ""
@export var speaker_emotion: SpeakerEmotion = SpeakerEmotion.NEUTRAL
@export var text_speed: float = 0.05
@export var audio_clip: AudioStream
@export var events: Array[String] = []  # Custom events to trigger
@export var wait_time: float = 0.0  # Additional wait after line
@export var auto_advance: bool = true  # Auto advance after wait_time

func _init(
	p_speaker_name: String = "",
	p_text: String = "",
	p_emotion: SpeakerEmotion = SpeakerEmotion.NEUTRAL):
	speaker_name = p_speaker_name
	text = p_text
	speaker_emotion = p_emotion
