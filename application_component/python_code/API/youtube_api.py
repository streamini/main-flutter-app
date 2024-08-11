import json
import requests

def get_youtube_link(search_term):
    print(search_term)
    # Parse the JSON data
    data = json.loads(search_term)

# Extract the value associated with the "youtube" key
    youtube_value = data["youtube"]
    url = "https://www.googleapis.com/youtube/v3/search"
    params = {
        "part": "snippet",
        "q": youtube_value,
        "key": "",
        "type": "video",  # You can also search for channels, playlists, etc.
        "maxResults": 1   # Number of results to retrieve
    }

    response = requests.get(url, params=params)
    if response.status_code == 200:
        result = response.json()
        if result["items"]:
            video_id = result["items"][0]["id"]["videoId"]
            video_url = f"https://www.youtube.com/watch?v={video_id}"
            return video_url
        else:
            return "No results found."
    else:
        return f"Error: {response.status_code}"

# Example usage
# api_key = "YOUR_API_KEY"
# search_term = "person walking on a road"
# print(get_youtube_link(search_term, api_key)) 