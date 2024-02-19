#' Download Mosquito Alert report data from GitHub
#'
#' @param source String. Source to download from. Currently only github works.
#' @returns A tibble.
#' @export
#' @examples
#' malert_reports = get_malert_data(source = "github")
#' malert_reports
get_malert_data = function(source = "github", doi = NA){
    temp <- tempfile()
    if(source == "github"){
    download.file("https://github.com/MosquitoAlert/Data/raw/master/all_reports.zip", destfile = temp)
    } else if(source == "zenodo" & !is.na(doi)){
      dir.create(temp, showWarnings = FALSE)
      n2khab::download_zenodo(doi = doi, path = temp)
      temp = file.path(temp, list.files(temp))
      unz(temp, file = this_file)
    } else{
  stop("Error: This function currently only supports downloads from Github")
}
    reports = bind_rows(lapply(2014:lubridate::year(lubridate::today()), function(this_year){
      print(this_year)
      flush.console()
      this_file = paste0("home/webuser/webapps/tigaserver/static/all_reports", this_year, ".json")
      jsonlite::fromJSON(unz(temp, file = this_file), flatten = TRUE) %>% as_tibble()
    }))
    unlink(temp)
    return(reports)

}
