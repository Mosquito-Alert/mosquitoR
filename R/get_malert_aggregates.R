#' Generates count by country of mosquito alert reports
#'
#' @param count_type String. Source to download from. Options are github or zenodo.
#' @param filter_year String. Zenodo doi if downloading from Zenodo. Default is the doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @param geopackage String. Zenodo doi if downloading from Zenodo. Default is the doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @param layer String. Zenodo doi if downloading from Zenodo. Default is the doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @returns A tibble.
#' @export
#' @examples
#' malert_reports = get_malert_data(source = "github")
#' malert_reports

malerts_reports_github = get_malert_data(source = "github")

if (filter_year is not null)
{
  malerts_reports_github <- malerts_reports_github %>%
    filter(year == "filter_year")
}

grouped_countries <- malerts_reports_github %>%
  group_by(country) %>%
  summarise(count = n())
  arrange(desc(count))
