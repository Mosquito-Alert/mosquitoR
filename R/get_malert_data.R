get_malert_data = function(source = "github"){
  if(source == "github"){
    temp <- tempfile()
    download.file("https://github.com/MosquitoAlert/Data/raw/master/all_reports.zip", destfile = temp)
    reports = bind_rows(lapply(2014:year(today()), function(this_year){
      print(this_year)
      flush.console()
      this_file = paste0("home/webuser/webapps/tigaserver/static/all_reports", this_year, ".json")
      fromJSON(unz(temp, file = this_file), flatten = TRUE) %>% as_tibble()
    }))
    unlink(temp)
    return(reports)
  }
  else{
    stop("Error: This function currently only supports downloads from Github")
  }
}