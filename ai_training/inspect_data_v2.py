import pandas as pd
import sys

output_file = "ai_training/ai_data_report.txt"

def log(msg):
    print(msg)
    with open(output_file, "a") as f:
        f.write(msg + "\n")

# Clear file
with open(output_file, "w") as f:
    f.write("")

try:
    path = r"c:\Users\Ammar\Downloads\1970-2021_DISASTERS.xlsx - emdat data.csv\1970-2021_DISASTERS.xlsx - emdat data.csv"
    
    log(f"Reading {path}...")
    df = pd.read_csv(path, on_bad_lines='skip', encoding='utf-8')
    
    log(f"Columns found: {df.columns.tolist()}")
    
    storms = df[ (df['Disaster Type'] == 'Storm') ]
    log(f"Total Storms: {len(storms)}")
    
    with_kph = storms[ (storms['Dis Mag Scale'] == 'Kph') & (storms['Dis Mag Value'].notna()) ]
    log(f"Storms with 'Kph' Wind Speed: {len(with_kph)}")
    
    if len(with_kph) > 0:
        log("\nSample Valid Data:")
        log(str(with_kph[['Disaster Type', 'Dis Mag Value', 'Country', 'Year']].head().to_string()))
    else:
        log("No valid wind speed data found for storms.")

except Exception as e:
    log(f"Error: {e}")
