import json
import speech_recognition as sr
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
from API.unsplash_api import unsplashimage
from audio_duration import get_audio_duration
from API.gemini_api import gemini_image
from speech_to_text import recognize

index = 0
def save_result_to_json(result, text):

    global index

    duration = get_audio_duration(f"audio/speech_{index}.wav")

    new_data = {
      "Scene": f"Scene{index}",
      "url": result, 
      "duration": duration,
      "title": text
    }
    index += 1
     
    """Function to append result to a JSON file in real-time."""
    results_file = "results.json"
    if not os.path.isfile(results_file):
        with open(results_file, "w") as file:
            file.write("[]")  # Initialize an empty list in the file if it doesn't exist

    with open(results_file, "r+") as file:
        data = json.load(file)
        data.append(new_data)
        file.seek(0)
        json.dump(data, file, indent=4)



def extract_audio():

    if os.path.exists("results.json"):
        os.remove("results.json")

    recognizer = sr.Recognizer()

    with sr.Microphone() as source:
        print("Adjusting for ambient noise, please wait...")
        recognizer.adjust_for_ambient_noise(source, duration=1)

        print("Listening... (press Ctrl+C to stop)")
        file_counter = 0
        alltext = []

        with ThreadPoolExecutor() as executor:
            futures = []
            while True:
                try:
                    audio_data = recognizer.listen(source)
                    audio_index = file_counter

                    audio_filename = f"audio/speech_{audio_index}.wav"
                    os.makedirs(os.path.dirname(audio_filename), exist_ok=True)
                    with open(audio_filename, "wb") as f:
                        f.write(audio_data.get_wav_data())

                    recognized_text = recognize(audio_data, recognizer, audio_index)
                    if recognized_text is not None:
                        alltext.append(recognized_text)
                        full_text = ' '.join(alltext)

                        future = executor.submit(
                            lambda: unsplashimage(
                                gemini_image(
                                    recognized_text,
                                    audio_index,
                                    full_text
                                ),                
                            )
                        )
                        future.add_done_callback(lambda fut: save_result_to_json(fut.result(), recognized_text))
                        futures.append(future)
                    else :
                        
                        if os.path.exists(f"audio/speech_{file_counter}.wav"):#delete none audio file
                            os.remove(f"audio/speech_{file_counter}.wav")
                        file_counter -= 1
                    print(future)

                  

                    file_counter += 1
                except KeyboardInterrupt:
                    print("Listening stopped by user.")
                    break

            for future in as_completed(futures):
                future.result()

extract_audio()