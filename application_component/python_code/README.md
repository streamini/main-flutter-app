# Streamini Backend

## Overview

Streamini Backend is a powerful backend framework designed to facilitate live streaming and recording workflows using OBS (Open Broadcaster Software). This project integrates speech-to-text capabilities, interacts with the Gemini API, fetches images from Google, and seamlessly manages OBS scenes.

## Project Structure

	•	main.py: Handles speech-to-text functionality, records audio, and generates prompts.
	•	gemini_api.py: Communicates with the Gemini API to process text.
	•	get_image.py: Fetches images from Google via web scraping.
	•	create_json.py: Creates data for easy content display.
	•	obs_addscene.py: Adds scenes to OBS by looping through JSON data.
	•	obs_change_scene.py: Changes the current OBS scene for streaming or recording.

## Features

	•	Speech-to-Text: Convert spoken words into text and generate prompts.
	•	API Integration: Seamless interaction with the Gemini API for text processing.
	•	Image Fetching: Retrieve relevant images from Google through web scraping.
	•	Content Management: Efficiently create and manage JSON data for display content.
	•	OBS Integration: Automate scene addition and switching in OBS.

## Getting Started

### Prerequisites

	•	Python 3.7+
	•	OBS WebSocket Plugin
	•	Required Python libraries (listed in requirements.txt)