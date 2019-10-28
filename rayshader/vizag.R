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

# load elevation data
# elev_img_fs <- 
elev_img <- crop(raster::raster("cdne44r.tif"),extent(82.99986,83.5,17.5,18.00014))

elev_matrix <- matrix(
  raster::extract(elev_img, raster::extent(elev_img), buffer = 1000), 
  nrow = ncol(elev_img), ncol = nrow(elev_img)
)



# plot 2D
elev_matrix %>%
  sphere_shade(texture = "imhof4") %>%
  add_water(watermap, color = "imhof4") %>%
  add_shadow(raymat, max_darken = 0.5) %>%
  add_shadow(ambmat, max_darken = 0.5) %>%
  plot_map()
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

elev_matrix %>%
  sphere_shade(texture = "imhof4") %>%
  add_water(watermap, color = "imhof4") %>%
  add_shadow(raymat, max_darken = 0.5) %>%
  add_shadow(ambmat, max_darken = 0.5) %>%
  add_overlay(overlay_img, alphalayer = 0.5) %>%
  plot_map()

zscale <- 10
rgl::clear3d()
# calculate rayshader layers
ambmat <- ambient_shade(elev_matrix1, zscale = zscale)
raymat <- ray_shade(elev_matrix1, zscale = zscale, lambert = TRUE)
watermap <- detect_water(elev_matrix1)
for (i in 0:29) {
rgl::clear3d()
elev_matrix1 %>% 
  sphere_shade(texture = "imhof2") %>% 
  add_water(watermap, color = "imhof2") %>%
  add_overlay(overlay_img, alphalayer = 0.5) %>%
  add_shadow(raymat, max_darken = 0.5) %>%
  add_shadow(ambmat, max_darken = 0.5) %>%
  plot_3d(elev_matrix1, zscale = zscale, windowsize = c(1200, 1000),watercolor = "imhof2",
          water = TRUE, wateralpha = 0.6,soliddepth = -60,waterdepth = 20+i,
          theta = 0, phi = 45, zoom = 0.65, fov = 60)  
render_snapshot(paste0("Test",i,".png",sep=""))
}


# You can do like this (assuming the images are in the current directory):

imgs <- list.files(pattern="*.png")
saveVideo({
  for(img in 0:29){
    im <- magick::image_read(paste0(img,".png",sep=""))
    plot(as.raster(im))
  }  
},video.name = "highrate.mp4")
paste0("Test",i,".png",sep="")
# plot_3d(elev_matrix, zscale = zscale, windowsize = c(1200, 1000),
#         water = TRUE, soliddepth = -max(elev_matrix)/zscale, wateralpha = 0,
#         theta = 45, phi = 45, zoom = 0.65, fov = 60)
montereybay=elev_matrix
median(elev_matrix)
elev_matrix1 <- elev_matrix + 88
elev_matrix1[elev_matrix1<0]=0
n_frames <- 15
waterdepths <- transition_values(from = 0, to = min(montereybay), steps = n_frames) 
thetas <- transition_values(from = -45, to = -135, steps = n_frames)
# generate gif
zscale <- 10
montereybay %>% 
  sphere_shade(texture = "imhof1", zscale = zscale) %>%
  add_shadow(ambient_shade(montereybay, zscale = zscale), 0.5) %>%
  add_shadow(ray_shade(montereybay, zscale = zscale, lambert = TRUE), 0.5) %>%
  plot_
  render_movie("test1",theta = -45, phi = 45)
  
  save_3d_gif(montereybay, file = "montereybay.gif", duration = 6,
              solid = TRUE, shadow = TRUE, water = TRUE, zscale = zscale,
              watercolor = "imhof3", wateralpha = 0.8, 
              waterlinecolor = "#ffffff", waterlinealpha = 0.5,
              waterdepth = waterdepths/zscale, 
              theta = -45, phi = 45)


raster::extent(elev_img)
montshadow = ray_shade(montereybay, zscale = 50, lambert = FALSE)
montamb = ambient_shade(montereybay, zscale = 50)
montereybay %>% 
  sphere_shade(zscale = 10, texture = "imhof1") %>% 
  add_shadow(montshadow, 0.5) %>%
  add_shadow(montamb) %>%
  plot_3d(montereybay, zscale = 50, fov = 0, theta = -45, phi = 45, windowsize = c(1000, 800), zoom = 0.75,
          water = TRUE, waterdepth = 0, wateralpha = 0.5, watercolor = "lightblue",
          waterlinecolor = "white", waterlinealpha = 0.5)


# ffmpeg -framerate 1 -i image%02d.png -s:v 1280x720 -c:v libx264 -profile:v high -crf 20 -pix_fmt yuv420p -r 3 clip.mp4
  
  # input frame rate
  # image names (image000.png, ..., image999.png)
  # video size
  # encoder
  # H.264 profile for video
  # constant rate factor
  # pixel format
  # output frame rate
