from pydub import AudioSegment

def get_audio_duration(file_path):
    audio = AudioSegment.from_file(file_path)
    duration = audio.duration_seconds  # duration in seconds
    return duration

#file_path = "audio/speech_0.wav"
#duration = get_audio_duration(file_path)
#print(f"Duration: {duration} seconds")