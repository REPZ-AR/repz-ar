import cv2
import mediapipe as mp
import json
import numpy as np
from mediapipe.tasks.python.vision.pose_landmarker import PoseLandmark

# Helper function to convert "LEFT_ELBOW" to "leftElbow"
def to_camel_case(snake_str):
    components = snake_str.lower().split('_')
    return components[0] + ''.join(x.title() for x in components[1:])

# 1. Setup MediaPipe Pose
BaseOptions = mp.tasks.BaseOptions
PoseLandmarker = mp.tasks.vision.PoseLandmarker
PoseLandmarkerOptions = mp.tasks.vision.PoseLandmarkerOptions
VisionRunningMode = mp.tasks.vision.RunningMode

# Path to your downloaded model (download from MediaPipe website)
model_path = 'pose_landmarker_heavy.task'

# Create the landmarker with VIDEO mode
options = PoseLandmarkerOptions(
    base_options=BaseOptions(model_asset_path=model_path),
    running_mode=VisionRunningMode.VIDEO)

landmarker = PoseLandmarker.create_from_options(options)

# 2. Open your video file
video_path = 'PXL_20260205_165258111.TS.mp4'
cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS)

frame_data = []
frame_index = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # MediaPipe needs RGB, OpenCV gives BGR
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

    # Calculate timestamp in ms (required for Video mode)
    timestamp_ms = int((frame_index / fps) * 1000)

    # Detect pose
    result = landmarker.detect_for_video(mp_image, timestamp_ms)

    # 3. Extract Data
    if result.pose_world_landmarks:
        landmarks = result.pose_world_landmarks[0]

        # CHANGED: Now a Dictionary (Map) instead of a List
        frame_landmarks = {}

        for i, lm in enumerate(landmarks):
            # Convert "LEFT_ELBOW" to "leftElbow" to match Dart's ML Kit output
            raw_name = PoseLandmark(i).name
            camel_case_name = to_camel_case(raw_name)

            # Map the data directly to the joint name key
            frame_landmarks[camel_case_name] = {
                'x': lm.x,
                'y': lm.y,
                'z': lm.z,
                'likelihood': lm.visibility # Renamed to match ML Kit's 'likelihood'
            }

        frame_data.append({
            'timestamp': timestamp_ms, # Changed to match Dart's 'timestamp' preference
            'landmarks': frame_landmarks
        })

    frame_index += 1

cap.release()

# 4. Save to JSON
with open('baseline_curls.json', 'w') as f:
    json.dump(frame_data, f, indent=2) # Added indent for readability

print(f"Processed {len(frame_data)} frames and saved to baseline_curls.json")