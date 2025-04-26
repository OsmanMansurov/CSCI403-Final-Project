Washington State Legislature district boundaries from 02/07/12 to 12/31/21 (shapefile)

##Redistricting Data Hub (RDH) Retrieval Date
01/20/21

##Sources
Special thanks to Professor Justin Levitt, founder of All About Redistricting (https://redistricting.lls.edu/) who compiled current and previous legislative boundaries, currently hosted on the AAR website, and shared his sources with the RDH to support our data collection efforts.
Washington State Legislature district boundaries for 02/07/12 to 12/31/21 were retrieved from https://redistricting.lls.edu/state/washington

##Processing
Washington State Legislature district boundaries were retrieved with a python script. 
The shapefiles were unzipped and uploaded to python and renamed with RDH conventions and zipped into a folder with supporting geospatial files and this README. 
Processing was primarily completed using the pandas and geopandas libraries.

##Additional Notes
For more information on the data see the AAR page at: https://redistricting.lls.edu/state/washington
Please direct questions related to processing this dataset to info@redistrictingdatahub.org
In Washington, the Washington House of Representative boundaries are the same as the Washington State Senate boundaries, as they are nested 2:1 and are therefore shown in this one shapefile.