import json
import numpy as np
import pandas as pd
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import LabelEncoder
import os

# --- Configuration ---
DATASET_PATH = 'dataset.csv'
OUTPUT_PATH = '../assets/risk_model_weights.json'

print(f"Loading dataset from {DATASET_PATH}...")

# 1. Load Data
# We expect columns: 'wind_speed', 'temperature', 'weather_code', 'risk_label'
if not os.path.exists(DATASET_PATH):
    print(f"Error: {DATASET_PATH} not found.")
    print("Please create a CSV with columns: wind_speed, temperature, weather_code, risk_label")
    # Create dummy for demonstration
    print("Creating dummy dataset for verification...")
    data = {
        'wind_speed': [10, 50, 90, 20, 100, 5, 60, 80], 
        'temperature': [20, 30, 40, 25, 45, 15, 35, 10], 
        'weather_code': [0, 60, 95, 0, 99, 1, 80, 55],
        'risk_label': ['Low', 'Medium', 'High', 'Low', 'Critical', 'Low', 'High', 'Medium']
    }
    pd.DataFrame(data).to_csv(DATASET_PATH, index=False)
    print("Dummy dataset created.")

df = pd.read_csv(DATASET_PATH)

# 2. Preprocess (Match Dart Logic in AIService)
def rain_severity(code):
    if code >= 95: return 1.0
    if code >= 80: return 0.8
    if code >= 60: return 0.6
    if code >= 50: return 0.4
    if code >= 45: return 0.2
    return 0.0

print("Preprocessing data...")
X = []
for _, row in df.iterrows():
    # Normalize inputs exactly as the Dart app does
    in1 = np.clip(row['wind_speed'] / 100.0, 0.0, 1.0)
    in2 = np.clip(row['temperature'] / 50.0, 0.0, 1.0)
    in3 = rain_severity(row['weather_code'])
    X.append([in1, in2, in3])

y_raw = df['risk_label'].values
le = LabelEncoder()
y = le.fit_transform(y_raw)
labels = le.classes_.tolist()

print(f"Target Labels: {labels}")

# 3. Train
print("Training Neural Network...")
# Simple architecture: 2 hidden layers with 8 neurons each
clf = MLPClassifier(
    hidden_layer_sizes=(8, 8), 
    activation='relu', 
    solver='adam', 
    max_iter=5000,
    random_state=42
)
clf.fit(X, y)
print(f"Training Accuracy: {clf.score(X, y):.2f}")

# 4. Extract Weights for Dart
model_config = {
    "labels": labels,
    "layers": []
}

# Sklearn coefs_: list of weight matrices. inputs -> layer1 -> layer2 -> outputs
# coefs_[i] has shape (n_inputs, n_neurons)
# Dart expects: weights[i][j] where it connects input j to neuron i.
# So we must TRANSPOSE the sklearn weights.

for i in range(len(clf.coefs_)):
    # Weight matrix: (n_inputs, n_neurons) -> Transpose to (n_neurons, n_inputs)
    w = clf.coefs_[i].T.tolist()
    b = clf.intercepts_[i].tolist()
    
    # Determine activation for this layer
    # Sklearn MLP uses 'relu' (configured above) for hidden layers
    # The output layer is linear (identity) in MLPClassifier's structure before Softmax
    
    activation = 'relu' # for hidden layers
    
    # If it's the last layer (output)
    if i == len(clf.coefs_) - 1:
        activation = 'softmax' 

    model_config["layers"].append({
        "weights": w,
        "biases": b,
        "activation": activation
    })

# 5. Save
print(f"Saving model to {OUTPUT_PATH}...")
try:
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(model_config, f, indent=2)
    print("Success! The AppModel weights have been updated.")
except Exception as e:
    print(f"Error saving file: {e}")
