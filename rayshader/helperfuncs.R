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

transition_values <- function(from, to, steps = 10, 
                              one_way = FALSE, type = "cos") {
  if (!(type %in% c("cos", "lin")))
    stop("type must be one of: 'cos', 'lin'")
  
  range <- c(from, to)
  middle <- mean(range)
  half_width <- diff(range)/2
  
  # define scaling vector starting at 1 (between 1 to -1)
  if (type == "cos") {
    scaling <- cos(seq(0, 2*pi / ifelse(one_way, 2, 1), length.out = steps))
  } else if (type == "lin") {
    if (one_way) {
      xout <- seq(1, -1, length.out = steps)
    } else {
      xout <- c(seq(1, -1, length.out = floor(steps/2)), 
                seq(-1, 1, length.out = ceiling(steps/2)))
    }
    scaling <- approx(x = c(-1, 1), y = c(-1, 1), xout = xout)$y 
  }
  
  middle - half_width * scaling
}

save_3d_gif <- function(hillshade, heightmap, file, duration = 5, ...) {
  require(rayshader)
  require(magick)
  require(rgl)
  require(gifski)
  require(rlang)
  
  # capture dot arguments and extract variables with length > 1 for gif frames
  dots <- rlang::list2(...)
  var_exception_list <- c("windowsize")
  dot_var_lengths <- purrr::map_int(dots, length)
  gif_var_names <- names(dots)[dot_var_lengths > 1 & 
                                 !(names(dots) %in% var_exception_list)]
  # split off dot variables to use on gif frames
  gif_dots <- dots[gif_var_names]
  static_dots <- dots[!(names(dots) %in% gif_var_names)]
  gif_var_lengths <- purrr::map_int(gif_dots, length)
  # build expressions for gif variables that include index 'i' (to use in the for loop)
  gif_expr_list <- purrr::map(names(gif_dots), ~rlang::expr(gif_dots[[!!.x]][i]))
  gif_exprs <- exprs(!!!gif_expr_list)
  names(gif_exprs) <- names(gif_dots)
  message(paste("gif variables found:", paste(names(gif_dots), collapse = ", ")))
  
  # TODO - can we recycle short vectors?
  if (length(unique(gif_var_lengths)) > 1) 
    stop("all gif input vectors must be the same length")
  n_frames <- unique(gif_var_lengths)
  
  # generate temp .png images
  temp_dir <- tempdir()
  img_frames <- file.path(temp_dir, paste0("frame-", seq_len(n_frames), ".png"))
  on.exit(unlink(img_frames))
  message(paste("Generating", n_frames, "temporary .png images..."))
  for (i in seq_len(n_frames)) {
    message(paste(" - image", i, "of", n_frames))
    rgl::clear3d()
    hillshade %>%
      plot_3d_tidy_eval(heightmap, !!!append(gif_exprs, static_dots))
    rgl::snapshot3d(img_frames[i])
  }
  
  # build gif
  message("Generating .gif...")
  magick::image_write_gif(magick::image_read(img_frames), 
                          path = file, delay = duration/n_frames)
  message("Done!")
  invisible(file)
}
plot_3d_tidy_eval <- function(hillshade, ...) {
  dots <- rlang::enquos(...)
  plot_3d_call <- rlang::expr(plot_3d(hillshade, !!!dots))
  rlang::eval_tidy(plot_3d_call)
}
