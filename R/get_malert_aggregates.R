#' Generates count by country of mosquito alert reports
#'
#' @param aggregate_type String. type of aggragation you would like. Options are country or city
#' @param filter_year String. The year(s) you would like to filter for. Default is all. "2014,2"
#' @param file_path String. Link the the geopackage or shapefile you would like to use.
#' @param country_code String. type of aggragation you would like. Options are country or city
#' @param file_layer String. the layer of the shapefile/geopackage to access
#' @returns The aggregated data.
#' @import sf
#' @import dplyr
#' @export
#' @examples
#' malert_reports = get_malert_data(source = "github")
#' malert_reports


get_malert_aggregates <- function(aggregate_type, filter_year, file_path, country_code, file_layer) {

malerts_reports_github = get_malert_data(source = "github")

# Handle multiple years or year range
if (!is.null(filter_year)) {

  if (grepl("-", filter_year)) { # Check if it's a range (e.g., "2011-2015")
    years <- as.numeric(unlist(strsplit(filter_year, "-")))
    filter_year <- seq(years[1], years[2])

  } else if (grepl(",", filter_year)) { # Check if it's a comma-separated list (e.g., "2021,2024,2023,2022")
    filter_year <- as.numeric(unlist(strsplit(filter_year, ",")))
  } else {
    filter_year <- as.numeric(filter_year) # Single year
  }

  malerts_reports_github <- malerts_reports_github %>%
    filter(creation_year %in% filter_year)
}

if(aggregate_type == "country")
{

  aggregated_data <- malerts_reports_github %>%
    group_by(country) %>%
    summarise(count = n()) %>%
  arrange(desc(count))

} else if (aggregate_type == "city")
{

  malerts_reports_github <- malerts_reports_github %>%
    filter(country == country_code)

  file_ext <- tools::file_ext(file_path)

  # Test if the file is a shapefile (.shp) or a GPKG file (.gpkg)
  if (file_ext == "shp") {
    polygon_file <- st_read(file_path)
  } else if (file_ext == "gpkg") {
    polygon_file <- st_read(file_path, layer = file_layer)
  } else {
    return("Unknown file type.")
  }

  malerts_reports_github <- st_as_sf(malerts_reports_github,
                                     coords = c("lon", "lat"),
                                     crs = 4326)

  malerts_reports_github <- st_join(malerts_reports_github,polygon_file)

  aggregated_data <- malerts_reports_github %>%
    group_by(file_layer) %>%
    summarise(count = n()) %>%
  arrange(desc(count))

}

return(aggregated_data)

}



