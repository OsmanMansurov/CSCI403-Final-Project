import geopandas as gpd
import pandas as pd
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import pg8000

from getpass import getpass

def makeColorColumn(gdf, variable, vmin, vmax):
    # apply a function to a column to create a new column of assigned colors & return full frame
    norm = mcolors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    mapper = plt.cm.ScalarMappable(norm=norm, cmap=plt.cm.RdBu)
    gdf['value_determined_color'] = gdf[variable].apply(lambda x: mcolors.to_hex(mapper.to_rgba(x)))
    return gdf

gdf = gpd.read_file('data/wa_sl_2012_to_2021')

username = input("Enter username for database access: ")
connection = pg8000.connect(user=username, password=getpass(), host="ada.mines.edu", port=5432, database="csci403")

cursor = connection.cursor()
cursor.execute('SET search_path TO group12;')
cursor.execute('SELECT district, party FROM legislative_data ;')
political_leanings = pd.DataFrame(cursor.fetchall(), columns=["district", "party"])
political_leanings.replace("Democrat", value=1.0, inplace=True)
political_leanings.replace("Republican", value=0.0, inplace=True)

heatmap_data = gdf.merge(political_leanings, left_on='OBJECTID', right_on='district')

variable = 'party'
vmin = heatmap_data[variable].min()
vmax = heatmap_data[variable].max()
heatmap_data = makeColorColumn(heatmap_data, variable, vmin, vmax)
heatmap_data_vis = heatmap_data.to_crs({'init':'epsg:3857'})

fig, ax = plt.subplots(1, figsize=(8, 4.5))
ax.axis('off')

for row in heatmap_data_vis.itertuples():
    vf = heatmap_data_vis[heatmap_data_vis["district"]==row.OBJECTID]
    c = heatmap_data[heatmap_data["district"]==row.OBJECTID][0:1].value_determined_color.item()
    vf.plot(color=c, edgecolors='k', linewidth=0.8, ax=ax)

plt.show()

connection.commit()
cursor.close()
connection.close()
