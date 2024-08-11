import google.generativeai as genai

genai.configure(api_key="")
model = genai.GenerativeModel(model_name="gemini-1.5-flash")


def gemini_image(recognized_text, audio_index, fulltext):
    prompt = f"""I want you to help find a suitable keyword for searching an image related to the sentence I am currently speaking, considering the previous sentence as well. 
Previous sentence: {fulltext}
Current sentence: {recognized_text}
Please provide only the keyword."""
    try:
        response = model.generate_content(prompt)
        print(f"Prompt: {prompt}\nResponse: {response.text}")
    except Exception as e:
        print(f"Error processing prompt: {prompt}\nError: {e}")
    
    
    return response.text


def gemini_image_sound(recognized_text, audio_index, fulltext):
    prompt = f"""
Generate a suitable keyword for creating an image and searching for ambient sound on YouTube based on the current and previous sentences. 
Please provide the response only JSON with the following structure:
{{
    "image": "keyword for the image",
    "youtube": "keyword for the ambient sound"
}}
Previous sentence: "{fulltext}"
Current sentence: "{recognized_text}"
"""
    try:
        response = model.generate_content(prompt)  # Ensure the output is in JSON format
        print(f"Prompt: {prompt}\nResponse: {response.text}")
        return response.text
    except Exception as e:
        print(f"Error processing prompt: {prompt}\nError: {e}")
        return response.text


def gemini_html(recognized_text, audio_index, fulltext):
    prompt = f"""Create an HTML presentation related to the sentence I am currently speaking, considering the previous sentence as well.
Previous sentence: "{fulltext}"
Current sentence: "{recognized_text}"
"""
    try:
        response = model.generate_content(prompt)
        print(f"Prompt: {prompt}\nResponse: {response.text}")
    except Exception as e:
        print(f"Error processing prompt: {prompt}\nError: {e}")
    
    
    return response.text

