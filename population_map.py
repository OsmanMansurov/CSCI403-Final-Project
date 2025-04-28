import geopandas as gpd
import pandas as pd
import math
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import pg8000

from getpass import getpass

# Function to make a color bar for a minimum and maximum value
def makeColorColumn(gdf, variable, vmin, vmax):
    norm = mcolors.Normalize(vmin=vmin*200000, vmax=vmax*200000, clip=True)
    mapper = plt.cm.ScalarMappable(norm=norm, cmap=plt.cm.YlOrRd)
    gdf['value_determined_color'] = gdf[variable].apply(lambda x: mcolors.to_hex(mapper.to_rgba(x)))
    return gdf

# Read in shape and population data
gdf = gpd.read_file('data/wa_cnty_2020_bound')
pop_data = pd.read_csv('data/wa_cit_2023_cnty/wa_cit_2023_cnty.csv')

# Process data
gdf['COUNTYFP20'] = gdf['COUNTYFP20'].astype(int)
heatmap_data = gdf.merge(pop_data, left_on='COUNTYFP20',right_on='COUNTYFP')
print(heatmap_data['TOT_POP23'].max())
variable = 'TOT_POP23'

# Construct colorbar
vmin = math.floor(heatmap_data[variable].min()/200000)
vmax = math.ceil(heatmap_data[variable].max()/200000)

heatmap_data = makeColorColumn(heatmap_data, variable, vmin, vmax)
heatmap_data_vis = heatmap_data.to_crs({'init':'epsg:3857'})

# Plot data
fig, ax = plt.subplots(1, figsize=(8, 4.5))
ax.axis('off')
plt.title("2023 Population by 2020 county in Washington state")
fig = ax.get_figure()

# Add colorbar
cbax = fig.add_axes([0.87, 0.05, 0.03, 0.6])
cbax.set_title('No. people\n(200k)', fontdict={'fontsize': '9', 'fontweight' : '0'})
cbax.tick_params(labelsize=7)

sm = plt.cm.ScalarMappable(cmap="YlOrRd", norm=plt.Normalize(vmin=vmin, vmax=vmax))
fig.colorbar(sm, cax=cbax)

# Iterate over counties and add to plot
for row in heatmap_data_vis.itertuples():
    vf = heatmap_data_vis[heatmap_data_vis["COUNTYFP20"]==row.COUNTYFP]
    c = heatmap_data[heatmap_data["COUNTYFP20"]==row.COUNTYFP][0:1].value_determined_color.item()
    vf.plot(color=c, edgecolors='k', linewidth=0.8, ax=ax)

plt.show()
