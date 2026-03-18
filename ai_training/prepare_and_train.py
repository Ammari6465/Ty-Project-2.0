import pandas as pd
import numpy as np
import json
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import LabelEncoder
import os

# --- Configuration ---
SOURCE_PATH = r"c:\Users\Ammar\Downloads\1970-2021_DISASTERS.xlsx - emdat data.csv\1970-2021_DISASTERS.xlsx - emdat data.csv"
# We assume the script is run from the project root
OUTPUT_WEIGHTS = 'assets/risk_model_weights.json'

print("--- AI Model Training Pipeline ---")

# 1. Load Real Data (Storms)
print(f"Loading real disaster data from: {SOURCE_PATH}")
try:
    df_raw = pd.read_csv(SOURCE_PATH, on_bad_lines='skip', encoding='utf-8')
except Exception as e:
    print(f"CRITICAL ERROR: Could not read file. {e}")
    exit(1)

# Filter: Only Storms with Wind Speed (Kph)
real_storms = df_raw[
    (df_raw['Disaster Type'] == 'Storm') & 
    (df_raw['Dis Mag Scale'] == 'Kph') & 
    (df_raw['Dis Mag Value'].notna())
].copy()

print(f"Found {len(real_storms)} usable storm events.")

# 2. Construct Real Dataset part
# We map 'Dis Mag Value' -> wind_speed
# We simulate Temperature (random 20-35C for tropical storms)
# We set Weather Code to 95 (Severe Storm)
# We set Label to 'High' or 'Critical' based on wind speed

dataset_real = pd.DataFrame()
dataset_real['wind_speed'] = real_storms['Dis Mag Value']
# Simulate temp for storms (warm air fuels cyclones)
dataset_real['temperature'] = np.random.uniform(22, 32, len(real_storms))
dataset_real['weather_code'] = 95 # Thunderstorm/Heavy 

def classify_storm(speed):
    if speed > 120: return 'Critical'
    if speed > 60: return 'High'
    return 'Medium'

dataset_real['risk_label'] = dataset_real['wind_speed'].apply(classify_storm)

# 3. Generate Synthetic "Safe" Data (To balance the model)
# If we only train on disasters, the AI will always predict disaster.
print("Generating synthetic 'Safe' weather data to balance training...")

n_safe = len(real_storms)
dataset_safe = pd.DataFrame()
dataset_safe['wind_speed'] = np.random.uniform(0, 30, n_safe) # 0-30 km/h
dataset_safe['temperature'] = np.random.uniform(10, 35, n_safe) # 10-35 C
# Random clear/cloudy codes (0,1,2,3, 45, etc)
dataset_safe['weather_code'] = np.random.choice([0, 1, 2, 3, 45, 51], n_safe)
dataset_safe['risk_label'] = 'Low'

# 4. Combine
full_df = pd.concat([dataset_real, dataset_safe], ignore_index=True)
full_df = full_df.sample(frac=1).reset_index(drop=True) # Shuffle

print(f"Total Training Samples: {len(full_df)}")
print(full_df['risk_label'].value_counts())

# 5. Preprocess for Neural Network (Match Dart Logic)
def rain_severity(code):
    if code >= 95: return 1.0
    if code >= 80: return 0.8
    if code >= 60: return 0.6
    if code >= 50: return 0.4
    if code >= 45: return 0.2
    return 0.0

print("Preprocessing features...")
X = []
for _, row in full_df.iterrows():
    # Normalize inputs exactly as the Dart app does
    in1 = np.clip(row['wind_speed'] / 100.0, 0.0, 1.0)
    in2 = np.clip(row['temperature'] / 50.0, 0.0, 1.0)
    in3 = rain_severity(row['weather_code'])
    X.append([in1, in2, in3])

y_raw = full_df['risk_label'].values
le = LabelEncoder()
y = le.fit_transform(y_raw)
labels = le.classes_.tolist()

print(f"Class labels: {labels}")

# 6. Train Neural Network
print("Training Neural Network...")
clf = MLPClassifier(
    hidden_layer_sizes=(12, 8), 
    activation='relu', 
    solver='adam', 
    max_iter=5000,
    random_state=42
)
clf.fit(X, y)
print(f"Model Accuracy: {clf.score(X, y)*100:.2f}%")

# 7. Export Weights to JSON
print(f"Exporting model to {OUTPUT_WEIGHTS}...")
model_config = {
    "labels": labels,
    "layers": []
}

for i in range(len(clf.coefs_)):
    w = clf.coefs_[i].T.tolist()
    b = clf.intercepts_[i].tolist()
    activation = 'relu' if i < len(clf.coefs_) - 1 else 'softmax'
    
    model_config["layers"].append({
        "weights": w,
        "biases": b,
        "activation": activation
    })

try:
    with open(OUTPUT_WEIGHTS, 'w') as f:
        json.dump(model_config, f, indent=2)
    print("SUCCESS: Model updated. Hot Reload your Flutter app to test.")
except Exception as e:
    print(f"Error saving JSON: {e}")
