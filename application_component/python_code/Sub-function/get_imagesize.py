import requests
from PIL import Image
from io import BytesIO

def get_image_size(url):
    # Send a GET request to the URL
    response = requests.get(url)
    
    # Check if the request was successful
    if response.status_code == 200:
        # Open the image using Pillow
        image = Image.open(BytesIO(response.content))
        # Get the image size
        return image.size  # Returns (width, height)
    else:
        raise Exception("Unable to download image")

# Example usage
url = 'https://media.npr.org/assets/img/2022/12/18/gettyimages-1450109553_custom-31cec7915f37a0c9c2bba2a83059053bea07f381.jpg'
try:
    width, height = get_image_size(url)
    print(f"The image size is {width}x{height} pixels.")
except Exception as e:
    print(e)