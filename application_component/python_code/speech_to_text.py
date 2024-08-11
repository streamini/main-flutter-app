import speech_recognition as sr

def recognize(audio_data, recognizer, audio_index):
    try:
        text = recognizer.recognize_google(audio_data)
        print(f"Recognized (audio {audio_index}): {text}")
        return text
    except sr.UnknownValueError:
        print(f"Could not understand audio {audio_index}")
        return None
    except sr.RequestError as e:
        print(f"Could not request results from Google Speech Recognition service for audio {audio_index}; {e}")
        return None