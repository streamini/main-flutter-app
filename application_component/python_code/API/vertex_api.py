import requests
import json
import base64

# Replace with the correct Gemini API endpoint and your API key
GEMINI_API_URL = 'https://api.gemini.com/correct-endpoint'
API_KEY = ''

# Define the data to send to the API
data = {
    "prompt": "a beautiful sunset over the ocean",  # Your prompt for the image generation
    "n": 1  # Number of images to generate
}

headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {API_KEY}'
}

# Send the request to the API
response = requests.post(GEMINI_API_URL, headers=headers, data=json.dumps(data))

# Check the response status
if response.status_code == 200:
    response_data = response.json()
    # Adjust the following line according to the actual API response structure
    image_data = response_data.get('image_base64')  # This should match the key where the image data is stored
    if image_data:
        # Decode the base64 string and save the image
        with open('generated_image.png', 'wb') as image_file:
            image_file.write(base64.b64decode(image_data))
        print('Image saved as generated_image.png')
    else:
        print('No image data found in the response')
else:
    print(f'Failed to generate image. Status code: {response.status_code}')
    print(f'Response: {response.text}')         