#' Generates count by country of mosquito alert reports
#'
#' @param aggregate_type String. type of aggragation you would like. Options are country or city
#' @param filter_year int. The year(s) you would like to filter for. Default is all
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

if(aggregate_type == "country")
{

  if (!is.null(filter_year))
      {
        malerts_reports_github <- malerts_reports_github %>%
          filter(year == filter_year)
  }


  aggregated_data <- malerts_reports_github %>%
    group_by(country) %>%
    summarise(count = n())
  arrange(desc(count))

} else if (aggregate_type == "city")
{

  if (!is.null(filter_year))
      {
        malerts_reports_github <- malerts_reports_github %>%
          filter(year == filter_year)
  }

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
    group_by(layer) %>%
    summarise(count = n())
  arrange(desc(count))

}


}



