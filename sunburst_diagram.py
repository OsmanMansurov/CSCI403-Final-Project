import geopandas as gpd
import pandas as pd
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import plotly.express as px
import plotly
import pg8000

from getpass import getpass
print(plotly.__version__)

def makeColorColumn(gdf, variable, vmin, vmax):
    # apply a function to a column to create a new column of assigned colors & return full frame
    norm = mcolors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    mapper = plt.cm.ScalarMappable(norm=norm, cmap=plt.cm.YlGnBu)
    gdf['value_determined_color'] = gdf[variable].apply(lambda x: mcolors.to_hex(mapper.to_rgba(x)))
    return gdf

gdf = gpd.read_file('data/wa_sl_2012_to_2021')

username = input("Enter username for database access: ")
password = getpass()

connection = pg8000.connect(user=username, password=password, host="ada.mines.edu", port=5432, database="csci403")

cursor = connection.cursor()
cursor.execute('SET search_path TO group12;')

cursor.execute('SELECT "Electric Vehicle Type", "Make", "Model", COUNT("VIN (1-10)") FROM vehicle_details GROUP BY "Electric Vehicle Type", "Make", "Model";')
vehicle_details = pd.DataFrame(cursor.fetchall(), columns=["EV_type", "make", "model", "count"])
vehicle_details = vehicle_details.copy()

fig = px.sunburst(
    vehicle_details,
    path=['EV_type', 'make'],
    values='count',
)
fig.show()

cursor.execute('SELECT "Model Year", "Electric Vehicle Type", "Make", COUNT("VIN (1-10)") FROM vehicle_details GROUP BY "Model Year", "Electric Vehicle Type", "Make";')
vehicle_details = pd.DataFrame(cursor.fetchall(), columns=["model_year", "EV_type", "make", "count"])
vehicle_details = vehicle_details.copy()

fig = px.sunburst(
    vehicle_details,
    path=['model_year', 'make'],
    values='count',
)
fig.show()

fig = px.sunburst(
    vehicle_details,
    path=['model_year', 'EV_type'],
    values='count',
)
fig.show()
'''
UPDATE vehicle_details SET "Electric Vehicle Type" = 'Battery EV' WHERE "Electric Vehicle Type" = 'Battery Electric Vehicle (BEV)';
UPDATE 2209
csci403=> SELECT * FROM vehicle_details;
csci403=> UPDATE vehicle_details SET "Electric Vehicle Type" = 'Hybrid EV' WHERE "Electric Vehicle Type" = 'Plug-in Hybrid Electric Vehicle (PHEV)';
UPDATE 5340
'''
connection.commit()
cursor.close()
connection.close()