import geopandas as gpd
import pandas as pd
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import plotly.express as px
import pg8000

from getpass import getpass

# Connect to the database
username = input("Enter username for database access: ")
password = getpass()

connection = pg8000.connect(user=username, password=password, host="ada.mines.edu", port=5432, database="csci403")

cursor = connection.cursor()
cursor.execute('SET search_path TO group12;')

# Grab data with a query
cursor.execute('SELECT "Electric Vehicle Type", "Make", "Model", COUNT("VIN (1-10)") FROM vehicle_location JOIN details_location USING ("DOL Vehicle ID") JOIN vehicle_details USING ("VIN (1-10)") WHERE "Model Year" < 2021 GROUP BY "Electric Vehicle Type", "Make", "Model";')
vehicle_details = pd.DataFrame(cursor.fetchall(), columns=["EV_type", "make", "model", "count"])
vehicle_details = vehicle_details.copy()

# Plot desired data as needed
fig = px.sunburst(
    vehicle_details,
    path=['EV_type', 'make'],
    values='count',
    title='EV type and make for EVs in Washington state'
)
fig.update_layout(title_x=0.5)
fig.show()

# Grab data with a query
cursor.execute('SELECT "Model Year", "Electric Vehicle Type", "Make", COUNT("VIN (1-10)") FROM vehicle_location JOIN details_location USING ("DOL Vehicle ID") JOIN vehicle_details USING ("VIN (1-10)") WHERE "Model Year" < 2021 GROUP BY "Model Year", "Electric Vehicle Type", "Make";')
vehicle_details = pd.DataFrame(cursor.fetchall(), columns=["model_year", "EV_type", "make", "count"])
vehicle_details = vehicle_details.copy()

# Plot desired data as needed
fig = px.sunburst(
    vehicle_details,
    path=['model_year', 'make'],
    values='count',
    title='Model year and make for EVs in Washington state'
)
fig.update_layout(title_x=0.5)
fig.show()

# Plot desired data as needed
fig = px.sunburst(
    vehicle_details,
    path=['model_year', 'EV_type'],
    values='count',
    title='Model year and EV type for vehicles in Washington state'
)
fig.update_layout(title_x=0.5)
fig.show()

# Grab data with a query
cursor.execute("""WITH vehicles_registered AS(
    SELECT "Make", "Legislative District"
    FROM ((vehicle_details JOIN details_location ON vehicle_details."VIN (1-10)"=details_location."VIN (1-10)") 
    JOIN vehicle_location ON details_location."DOL Vehicle ID"=vehicle_location."DOL Vehicle ID")
)
SELECT "Make" AS make, COUNT(*) AS count, party
FROM legislative_data JOIN vehicles_registered ON legislative_data.district = vehicles_registered."Legislative District"
GROUP BY "Make",party ORDER BY "Make", count DESC;""")
vehicle_details = pd.DataFrame(cursor.fetchall(), columns=["make", "count", "party"])
vehicle_details = vehicle_details.copy()

# Plot desired data as needed
fig = px.sunburst(
    vehicle_details,
    path=['party', 'make'],
    values='count',
    title='Make and political party in Washington state'
)
fig.update_layout(title_x=0.5)
fig.show()

# Commit edits and close database connection
connection.commit()
cursor.close()
connection.close()