import requests
import threading


def download_image(url, file_path):
    try:
        # Send a GET request to the URL
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Will raise an HTTPError if the HTTP request returned an unsuccessful status code

        # Open a local file with write-binary mode
        with open(file_path, 'wb') as file:
            # Write the content in chunks to avoid memory issues with large files
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
                
        print(f"Image successfully downloaded: {file_path}")
       
    
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

def download_image_thread(url, file_path):
    download_thread = threading.Thread(target=download_image, args=(url, file_path))
    download_thread.start()
    return download_thread

# Example usage
# image_url = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvRfUMb6dcA2rukTA_FwStgw7r6TgayH1E3g&s"
# download_path = "local_image.jpg"
# download_image(image_url, download_path)