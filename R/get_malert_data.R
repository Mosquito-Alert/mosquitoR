#' Download Mosquito Alert report data from GitHub
#'
#' @param source String. Source to download from. Options are github or zenodo.
#' @param doi String. Zenodo doi if downloading from Zenodo. Default is the doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @returns A tibble.
#' @export
#' @examples
#' malert_reports = get_malert_data(source = "github")
#' malert_reports
get_malert_data = function(source = "zenodo", doi = "10.5281/zenodo.597466"){
    this_temp_file <- tempfile()
    if(source == "github"){
      temp = this_temp_file
    download.file("https://github.com/MosquitoAlert/Data/raw/master/all_reports.zip", destfile = temp)
    } else if(source == "zenodo" & !is.na(doi)){
      dir.create(this_temp_file, showWarnings = FALSE)
      download_zenodo(doi = doi, path = this_temp_file)
      this_file = list.files(this_temp_file)
      this_temp_file_zip = file.path(this_temp_file, list.files(this_temp_file))
      outer_file_name = unzip(this_temp_file_zip, exdir = temp, list = TRUE)[1,1]
      unzip(this_temp_file_zip, exdir = this_temp_file)
      temp = file.path(this_temp_file, outer_file_name, "all_reports.zip")
    } else{
  stop("Error: This function currently only supports downloads from Github or Zenodo")
}
    reports = bind_rows(lapply(2014:lubridate::year(lubridate::today()), function(this_year){
      print(this_year)
      flush.console()
      this_file = paste0("home/webuser/webapps/tigaserver/static/all_reports", this_year, ".json")
      jsonlite::fromJSON(unz(temp, file = this_file), flatten = TRUE) %>% as_tibble()
    }))
    unlink(this_temp_file)
    return(reports)
}
