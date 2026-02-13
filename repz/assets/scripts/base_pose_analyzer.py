import cv2
import mediapipe as mp
import json
import numpy as np
from mediapipe.tasks.python.vision.pose_landmarker import PoseLandmark

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
    # We check if any pose was detected in this frame
    if result.pose_world_landmarks:
        landmarks = result.pose_world_landmarks[0]
    frame_landmarks = []

    # Use enumerate to get the index (i) for each landmark
    for i, lm in enumerate(landmarks):
        # Map the index to the human-readable name
        landmark_name = PoseLandmark(i).name

        frame_landmarks.append({
            'index': i,
            'joint': landmark_name, # This will now be "LEFT_ELBOW", etc.
            'x': lm.x,
            'y': lm.y,
            'z': lm.z,
            'visibility': lm.visibility
        })

    frame_data.append({
        'timestamp_ms': timestamp_ms,
        'landmarks': frame_landmarks
    })

    frame_index += 1

cap.release()

# 4. Save to JSON
with open('baseline_curls.json', 'w') as f:
    json.dump(frame_data, f)

print(f"Processed {len(frame_data)} frames and saved to baseline_curls.json")