import json
import requests

access_key = "KQo4fAOGHaCBnxvSf_oMDJBCQfV9yrH-TgDEJINGTUk"


def unsplashimage(search_term):
    data = json.loads(search_term)

# Extract the value associated with the "youtube" key
    search_term = data["image"]
    url = f"https://api.unsplash.com/search/photos?page=1&query={search_term}&client_id={access_key}"
    response = requests.get(url)
    search_results = response.json()

    # Print the URL of the first image
    first_image_url = search_results['results'][0]['urls']['regular']
    print(first_image_url)
    return first_image_url