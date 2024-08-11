import cv2
import ffmpeg

# Define the duration of the video capture in seconds
duration = 10  # You can change this to the desired duration

# Open a connection to the webcam (0 is the default camera)
cap = cv2.VideoCapture(0)

# Check if the webcam is opened correctly
if not cap.isOpened():
    print("Error: Could not open webcam.")
    exit()

# Get the width and height of the frame
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = int(cap.get(cv2.CAP_PROP_FPS)) or 30  # Fallback to 30 fps if fps is not available

# Define the codec and create VideoWriter object to save the video
output_file = 'output.mp4'
fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # Codec for mp4
out = cv2.VideoWriter(output_file, fourcc, fps, (frame_width, frame_height))

# Capture video for the specified duration
print(f"Recording video for {duration} seconds...")
start_time = cv2.getTickCount()

while (cv2.getTickCount() - start_time) / cv2.getTickFrequency() < duration:
    ret, frame = cap.read()
    if not ret:
        break
    out.write(frame)

# Release the webcam and the video writer
cap.release()
out.release()

# Print a message indicating that the video has been saved
print(f"Video saved as {output_file}")