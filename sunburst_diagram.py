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

#username = input("Enter username for database access: ")
username = "omansurov"
#password = getpass()
password = "Padajdee123!@#"
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
heatmap_data = gdf.merge(car_counts, left_on='OBJECTID',right_on='district')

variable = 'car_counts'
vmin = math.floor(heatmap_data[variable].min()/1000)*1000
vmax = math.ceil(heatmap_data[variable].max()/1000)*1000
heatmap_data = makeColorColumn(heatmap_data, variable, vmin, vmax)
heatmap_data_vis = heatmap_data.to_crs({'init':'epsg:3857'})

fig, ax = plt.subplots(1, figsize=(8, 4.5))
ax.axis('off')
fig = ax.get_figure()
cbax = fig.add_axes([0.87, 0.05, 0.03, 0.6])
cbax.set_title('No. Electrical\nVehicles', fontdict={'fontsize': '9', 'fontweight' : '0'})
cbax.tick_params(labelsize=7)

sm = plt.cm.ScalarMappable(cmap="YlGnBu", norm=plt.Normalize(vmin=vmin, vmax=vmax))
fig.colorbar(sm, cax=cbax)

for row in heatmap_data_vis.itertuples():
    vf = heatmap_data_vis[heatmap_data_vis["district"]==row.OBJECTID]
    c = heatmap_data[heatmap_data["district"]==row.OBJECTID][0:1].value_determined_color.item()
    vf.plot(color=c, edgecolors='k', linewidth=0.8, ax=ax)

plt.show()
'''
connection.commit()
cursor.close()
connection.close()