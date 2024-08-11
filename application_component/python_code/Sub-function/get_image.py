import time
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup



index = 0
# Function to perform a search query
def perform_search(query):
    query = query.replace(' ', '+')
    url = f"https://www.google.com/search?hl=en&tbm=isch&tbs=isz:l&q={query}"

    # Set up Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")

    # Setup the WebDriver (Chrome in this case)
    #driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()))
    # Initialize the WebDriver
    driver = webdriver.Chrome(options=chrome_options)
    
    # Open the browser and go to a search engine
    driver.get(url)
    
    # Wait for the first image result to be clickable
    wait = WebDriverWait(driver, 15)
    first_image = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="rso"]/div/div/div[1]/div/div/div[1]')))
    first_image.click()

    time.sleep(3)#wait for full resolution image load
        
    # Wait for the image preview to load
    element = wait.until(EC.visibility_of_element_located((By.XPATH, '//*[@id="Sva75c"]/div[2]/div[2]/div/div[2]/c-wiz/div/div[3]/div[1]/a/img[1]')))

    
    # Get the HTML content of the specific element
    element_html = element.get_attribute('outerHTML')

    # Parse the HTML content using BeautifulSoup
    soup = BeautifulSoup(element_html, 'html.parser')
    print(soup.prettify())

    html = soup.prettify()
    soup = BeautifulSoup(html, 'html.parser')
    
    img_tag = soup.find('img')
    img_src = img_tag['src']


    driver.quit()
    
    return img_src

