import geopandas as gpd
import pandas as pd
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import plotly.express as px
import pg8000

from getpass import getpass

username = input("Enter username for database access: ")
password = getpass()

connection = pg8000.connect(user=username, password=password, host="ada.mines.edu", port=5432, database="csci403")

cursor = connection.cursor()
cursor.execute('SET search_path TO group12;')

cursor.execute('SELECT "Electric Vehicle Type", "Make", "Model", COUNT("VIN (1-10)") FROM vehicle_location JOIN details_location USING ("DOL Vehicle ID") JOIN vehicle_details USING ("VIN (1-10)") WHERE "Model Year" < 2021 GROUP BY "Electric Vehicle Type", "Make", "Model";')
vehicle_details = pd.DataFrame(cursor.fetchall(), columns=["EV_type", "make", "model", "count"])
vehicle_details = vehicle_details.copy()

fig = px.sunburst(
    vehicle_details,
    path=['EV_type', 'make'],
    values='count',
)
fig.show()

cursor.execute('SELECT "Model Year", "Electric Vehicle Type", "Make", COUNT("VIN (1-10)") FROM vehicle_location JOIN details_location USING ("DOL Vehicle ID") JOIN vehicle_details USING ("VIN (1-10)") WHERE "Model Year" < 2021 GROUP BY "Model Year", "Electric Vehicle Type", "Make";')
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

connection.commit()
cursor.close()
connection.close()