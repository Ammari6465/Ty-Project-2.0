import pandas as pd

try:
    path = r"c:\Users\Ammar\Downloads\1970-2021_DISASTERS.xlsx - emdat data.csv\1970-2021_DISASTERS.xlsx - emdat data.csv"
    # Skip first row because the header is on line 1, but the data snippet showed headers.
    df = pd.read_csv(path, on_bad_lines='skip', encoding='utf-8')
    
    print("Columns:", df.columns.tolist())
    
    # Check for Storms with Magnitude
    storms = df[ (df['Disaster Type'] == 'Storm') & (df['Dis Mag Scale'] == 'Kph') ]
    print(f"\nTotal Storms with Kph scale: {len(storms)}")
    
    valid_storms = storms[ storms['Dis Mag Value'].notna() ]
    print(f"Storms with valid Wind Speed (Mag Value): {len(valid_storms)}")
    
    if len(valid_storms) > 0:
        print("\nSample Valid Data:")
        print(valid_storms[['Disaster Type', 'Dis Mag Value', 'Total Deaths']].head())
        
except Exception as e:
    print(e)
