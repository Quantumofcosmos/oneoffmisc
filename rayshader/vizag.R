library(tidyverse)
library(rayshader)
library(leaflet)
library(raster)
library(animation)

# define bounding box with longitude/latitude coordinates
bbox <- list(
  p1 = list(long = 82.99986, lat = 17.5),
  p2 = list(long = 83.5, lat = 18.00014)
)
# Check if the selection is correct
leaflet() %>%
  addTiles() %>% 
  addRectangles(
    lng1 = bbox$p1$long, lat1 = bbox$p1$lat,
    lng2 = bbox$p2$long, lat2 = bbox$p2$lat,
    fillColor = "transparent"
  ) %>%
  fitBounds(
    lng1 = bbox$p1$long, lat1 = bbox$p1$lat,
    lng2 = bbox$p2$long, lat2 = bbox$p2$lat,
  )

# Get street map to overlay on 
get_arcgis_map_image <-
  function(bbox,
           map_type = "World_Street_Map",
           file = NULL,
           width = 400,
           height = 400,
           sr_bbox = 4326) {
    require(httr)
    require(glue)
    require(jsonlite)
    
    url <-
      parse_url(
        "https://utility.arcgisonline.com/arcgis/rest/services/Utilities/PrintingTools/GPServer/Export%20Web%20Map%20Task/execute"
      )
    
    # define JSON query parameter
    web_map_param <- list(
      baseMap = list(baseMapLayers = list(list(
        url = jsonlite::unbox(
          glue(
            "https://services.arcgisonline.com/ArcGIS/rest/services/{map_type}/MapServer",
            map_type = map_type
          )
        )
      ))),
      exportOptions = list(outputSize = c(width, height)),
      mapOptions = list(
        extent = list(
          spatialReference = list(wkid = jsonlite::unbox(sr_bbox)),
          xmax = jsonlite::unbox(max(bbox$p1$long, bbox$p2$long)),
          xmin = jsonlite::unbox(min(bbox$p1$long, bbox$p2$long)),
          ymax = jsonlite::unbox(max(bbox$p1$lat, bbox$p2$lat)),
          ymin = jsonlite::unbox(min(bbox$p1$lat, bbox$p2$lat))
        )
      )
    )
    
    res <- GET(
      url,
      query = list(
        f = "json",
        Format = "PNG32",
        Layout_Template = "MAP_ONLY",
        Web_Map_as_JSON = jsonlite::toJSON(web_map_param)
      )
    )
    
    if (status_code(res) == 200) {
      body <- content(res, type = "application/json")
      message(jsonlite::toJSON(body, auto_unbox = TRUE, pretty = TRUE))
      if (is.null(file))
        file <- tempfile("overlay_img", fileext = ".png")
      
      img_res <- GET(body$results[[1]]$value$url)
      img_bin <- content(img_res, "raw")
      writeBin(img_bin, file)
      message(paste("image saved to file:", file))
    } else {
      message(res)
    }
    invisible(file)
  }

define_image_size <- function(bbox, major_dim = 400) {
  # calculate aspect ration (width/height) from lat/long bounding box
  aspect_ratio <- abs((bbox$p1$long - bbox$p2$long) / (bbox$p1$lat - bbox$p2$lat))
  # define dimensions
  img_width <- ifelse(aspect_ratio > 1, major_dim, major_dim*aspect_ratio) %>% round()
  img_height <- ifelse(aspect_ratio < 1, major_dim, major_dim/aspect_ratio) %>% round()
  size_str <- paste(img_width, img_height, sep = ",")
  list(height = img_height, width = img_width, size = size_str)
}

elev_img <- crop(raster::raster("cdne44r.tif"),extent(82.99986,83.5,17.5,18.00014))

elev_matrix <- matrix(
  raster::extract(elev_img, raster::extent(elev_img), buffer = 1000), 
  nrow = ncol(elev_img), ncol = nrow(elev_img)
)



image_size <- define_image_size(bbox, major_dim = 600)
overlay_file <- "vizag-map.png"
get_arcgis_map_image(bbox, map_type = "World_Topo_Map", file = overlay_file,
                     width = image_size$width, height = image_size$height, 
                     sr_bbox = 4326)

overlay_img <- png::readPNG(overlay_file)

resized_overlay_file = paste0(tempfile(),".png")
grDevices::png(filename = resized_overlay_file, width = dim(elev_matrix)[1], height = dim(elev_matrix)[2])
par(mar = c(0,0,0,0))
plot(as.raster(overlay_img))
dev.off()
overlay_img = png::readPNG(resized_overlay_file)
rm(resized_overlay_file)

# median(elev_matrix)
# elev_matrix1[elev_matrix1<0]=0
elev_matrix1 <- elev_matrix + 88


zscale <- 10
# calculate rayshader layers
ambmat <- ambient_shade(elev_matrix1, zscale = zscale)
raymat <- ray_shade(elev_matrix1, zscale = zscale, lambert = TRUE)
watermap <- detect_water(elev_matrix1)
for (i in 0:29) {
print(i)
rgl::clear3d()
elev_matrix1 %>% 
  sphere_shade(texture = "imhof4") %>% 
  add_water(watermap, color = "imhof4") %>%
  add_overlay(overlay_img, alphalayer = 0.5) %>%
  add_shadow(raymat, max_darken = 0.5) %>%
  add_shadow(ambmat, max_darken = 0.5) %>%
  plot_3d(elev_matrix1, zscale = zscale, windowsize = c(1200, 1000),watercolor = "imhof2",
          water = TRUE, wateralpha = 0.6,soliddepth = -60,waterdepth = 20+i,
          theta = 0, phi = 45, zoom = 0.65, fov = 60)  
render_snapshot(paste0("Vizag",sprintf("%02d",i),".png"))
}

# convert -delay 1x2 *.png -coalesce -dispose previous animation1.gif
system("ffmpeg -framerate 1 -i Vizag%02d.png -s:v 1280x720 -codec:v mpeg4 -profile:v high -q 10 -pix_fmt yuv420p -r 3 Vizag.mp4")

# ffmpeg -framerate 1 -i image%02d.png -s:v 1280x720 -c:v libx264 -profile:v high -crf 20 -pix_fmt yuv420p -r 3 clip.mp4
  
  # input frame rate
  # image names (image000.png, ..., image999.png)
  # video size
  # encoder
  # H.264 profile for video
  # constant rate factor
  # pixel format
  # output frame rate

