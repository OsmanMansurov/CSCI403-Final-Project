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
    mapper = plt.cm.ScalarMappable(norm=norm, cmap=plt.cm.RdBu)
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
cursor.execute('SELECT district, party FROM legislative_data ;')
political_leanings = pd.DataFrame(cursor.fetchall(), columns=["district", "party"])
# Replace democ and repub with 0 or 1 for coloring on final plot
political_leanings.replace("Democrat", value=1.0, inplace=True)
political_leanings.replace("Republican", value=0.0, inplace=True)

heatmap_data = gdf.merge(political_leanings, left_on='OBJECTID', right_on='district')

# Construct dataframe for the data to plot
variable = 'party'
vmin = heatmap_data[variable].min()
vmax = heatmap_data[variable].max()
heatmap_data = makeColorColumn(heatmap_data, variable, vmin, vmax)
heatmap_data_vis = heatmap_data.to_crs({'init':'epsg:3857'})

# Plot data
fig, ax = plt.subplots(1, figsize=(8, 4.5))
ax.axis('off')
plt.title("Political allegiance in Washington state, 2020")

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
