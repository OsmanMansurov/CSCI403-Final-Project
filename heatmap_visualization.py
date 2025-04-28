import geopandas as gpd
import pandas as pd
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import pg8000

from getpass import getpass

# Function to make a color bar for a minimum and maximum value
def makeColorColumn(gdf, variable, vmin, vmax):
    norm = mcolors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    mapper = plt.cm.ScalarMappable(norm=norm, cmap=plt.cm.YlGnBu)
    gdf['value_determined_color'] = gdf[variable].apply(lambda x: mcolors.to_hex(mapper.to_rgba(x)))
    return gdf

# Read in shape data
gdf = gpd.read_file('data/wa_sl_2012_to_2021')

# Connect to the database
username = input("Enter username for database access: ")
connection = pg8000.connect(user=username, password=getpass(), host="ada.mines.edu", port=5432, database="csci403")

# Grab data with a query
cursor = connection.cursor()
cursor.execute('SET search_path TO group12;')
cursor.execute('SELECT "Legislative District" AS district, COUNT("DOL Vehicle ID") AS car_count FROM vehicle_location JOIN details_location USING ("DOL Vehicle ID") JOIN vehicle_details USING ("VIN (1-10)") WHERE "Legislative District" IS NOT NULL AND "Model Year" < 2021 GROUP BY "Legislative District" ORDER BY district;')
car_counts = pd.DataFrame(cursor.fetchall(), columns=["district", "car_counts"])

heatmap_data = gdf.merge(car_counts, left_on='OBJECTID',right_on='district')

# Construct dataframe for the data to plot
variable = 'car_counts'
vmin = math.floor(heatmap_data[variable].min()/1000)*1000
vmax = math.ceil(heatmap_data[variable].max()/1000)*1000
heatmap_data = makeColorColumn(heatmap_data, variable, vmin, vmax)
heatmap_data_vis = heatmap_data.to_crs({'init':'epsg:3857'})

# Plot data
fig, ax = plt.subplots(1, figsize=(8, 4.5))
ax.axis('off')
fig = ax.get_figure()
plt.title("Distribution of electrical vehicles over legislative districts in Washington state")

# Add colorbar
cbax = fig.add_axes([0.87, 0.05, 0.03, 0.6])
cbax.set_title('No. Electrical\nVehicles', fontdict={'fontsize': '9', 'fontweight' : '0'})
cbax.tick_params(labelsize=7)

sm = plt.cm.ScalarMappable(cmap="YlGnBu", norm=plt.Normalize(vmin=vmin, vmax=vmax))
fig.colorbar(sm, cax=cbax)

# Iterate over districts and add to plot
for row in heatmap_data_vis.itertuples():
    vf = heatmap_data_vis[heatmap_data_vis["district"]==row.OBJECTID]
    c = heatmap_data[heatmap_data["district"]==row.OBJECTID][0:1].value_determined_color.item()
    vf.plot(color=c, edgecolors='k', linewidth=0.8, ax=ax)

plt.show()

# Commit edits and close database connection
connection.commit()
cursor.close()
connection.close()