This repository contains the tools needed to classify any black and white aerial imagery or orthomosaic. 
Rather than colorizing the image, the process presented here creates a set of data around the orthoimage that informs the actual classification. 

Requires users to have on hand:
1) The orthomosaic they wish to classify as a raster file
2) A shapefile defining their study area
3) Solar zenith angle and solar azimuth values
    > Calculated using date and time image was taken. Can be estimated using shadow length from a building of known height
    > Tools such as https://gml.noaa.gov/grad/solcalc/azel.html may be used to find necessary values
5) A DEM raster
    > Can be retrieved from sources such as https://earthexplorer.usgs.gov/ or from any GIS service local to your study area
6) [Optional] An AET raster.
    > Can be retrieved from sources such as https://earlywarning.usgs.gov/ssebop/
Also requires users to manually classify a set of ground truth points, requiring the use of a GIS program such as ArcGIS Pro


Sources:

Lydersen, J. M., & Collins, B. M. (2018). Change in vegetation patterns over a large forested 
landscape based on historical and contemporary aerial photography. Ecosystems, 21(7), 
1348–1363. https://doi.org/10.1007/s10021-018-0225-5

