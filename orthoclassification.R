##B&W Orthomosaic Classification--randomForest Application##
##Created by Anne Petty for Rebecca Lave--IU Bloomington--2026##

##To run this code, please insert the relevant files and values where indicated. 
##This will require your orthomosaic, a shapefile of your study area, a DEM for the area, and a raster of AET for the area, if available.
##Make sure all of your input files are in the same coordinate reference system before starting.

#Setup
setwd("C:/Users/name/place/folder")
require(raster)
require(randomForest)
require(tidyterra)
require(terra)
require(sf)
require(ggplot2)
require(whitebox) #If first time installing whitebox, run next three lines
#install_whitebox()
#whitebox::wbt_init()
#theme_set(theme_classic())

sr <- "epsg:32615" #Set your preferred CRS

border = st_read("C:/user/name/place/shapefile.shp")
border2 = st_transform(border, cr = 32615)
extent(border2)
sa = rast(xmin = 659590.7, xmax = 694696.5, ymin = 4730324, ymax = 4762799, crs = "epsg:32615", res = c(10,10)) #Create a Study Area raster using the extent of your border shapefile

# Generating Data ---------------------------------------------------------
band1 = rast("C:/user/name/place/orthoimage.tif", lyrs = 1)
dem = rast("C:/user/name/place/dem.tif")
aet = rast("C:/user/name/place/aet.tif")
Z = dem

#####Cropping and Resampling######
#crop(band1, sa)
#project(band1, "epsg:32615")
#project(dem, "epsg:32615")
#extend(dem, sa)
#project(aet, "epsg:32615")
#extend(aet, sa)

#Slope and Aspect
slope = terrain(dem, 'slope', unit='degrees')
#crop(slope, sa)
aspect = terrain(dem, 'aspect', unit = 'degrees')
#crop(aspect, sa)

#Topographic Wetness Index
wbt_hillshade(dem = dem,
              output = "hillshade.tif",
              azimuth = 184)
hillshade <- rast("hillshade.tif")
wbt_d_inf_flow_accumulation(input = dem,
                            output = "FA.tif",
                            out_type = "Specific Contributing Area")
wbt_slope(dem = dem,
          output = "demslope.tif",
          units = "degrees")
wbt_wetness_index(sca = "FA.tif",
                  slope = "demslope.tif",
                  output = "TWI.tif")
twi <- rast("TWI.tif")
twi[twi > 0] <- NA
#crop(twi, sa)

#Radiometric Correction
theta = as.numeric(VALUE) #Solar Zenith Angle
alpha = slope 
phi = as.numeric(VALUE) #Solar Azimuth
#These values can be calculated using online tools such as the NOAA sun position calculator, if date and time are known. 
#If date and time are not known, try estimating using an online sun position tool and the length of a shadow in the image from a structure of known height.

cosi = (cos(theta)*cos(alpha)+sin(theta)*sin(alpha)*cos(phi))
ia = acos(cosi)

hillshade = hillShade(slope, aspect, angle = ia, direction = phi) #Radiometric hillshade, as opposed to the DEM hillshade calculated for TWI
#crop(hillshade, sa)

#####Cropping and Resampling#######
#cosi_proj = project(cosi, "epsg:32615")
#hillshade_proj = project(hillshade, "epsg:32615")
#band1_resampled = resample(band1, hillshade_proj)
#band1_crop = crop(band1_resampled, sa)
#hs_crop = crop(hillshade_proj, sa)
#cosi_resample = resample(cosi_proj, band1_crop)
#hs_resample = resample(hs_crop, band1_crop)

#Radiometric Correction pt. 2
b0 = hillshade-(band1*cosi)
C = b0/band1
#C_proj= project(C, "epsg:32615")
brightness = hillshade * ((cos(theta)+C)/(cosi+C))

#Composite Bands
composite = rast(c(band1, aet, Z, slope, aspect, brightness, twi))
comp = crop(composite, border2)

# Sampling Points ---------------------------------------------------------
points <- st_sample(border, size = 300, type = "random")
points_sf <- st_sf(points)
values = extract(slope, points_sf, method = "simple")
pointvals = data.frame(values)

#Coordinates and Shapefile

st_write(pointvals, "pointvals.shp")
write.csv(pointvals, "pointvals.csv")

#Using these points, it is necessary to manually identify which class each point belongs to using a software like ArcGIS Pro.
#By adding a column called "classvalue," assign integers to represent each class you would like your model to identify. 
#You can add a column called "class" with corresponding class names as text for easier interpretation. 
#More points = more data to sample, and thus a more accurate classification model. 
#These points then become your "ground truth" data.
#Finally, please import a csv file containing the updated data for these ground truth points as the variable "intable."

# randomForest ------------------------------------------------------------
#This section of the code may be used independently if the input variables and final composite image have already been generated in other software. 
#It may be necessary to rename the bands of the composite raster. If so, use composite %>% rename

compb = na.omit(comp)

intable = read.csv("C:/Users/name/place/folder/groundtruth.csv", fileEncoding="UTF-16LE")
table = na.omit(intable)

myrf = randomForest(factor(class) ~ band1 + Z + slope + aspect + twi + aet + brightness, data = table, na.omit = NULL, ntree = 2500)
plot(myrf) #To check if the number of prediction trees exceeds the error threshold
varImpPlot(myrf, sort = TRUE) #To visualize which variables are the most important in your model

predict(composite, myrf, filename="classified.tif", type="response", na.rm=TRUE, overwrite=TRUE, progress="window") 


