library(tidyverse)
library(lubridate)
cell_mask = .05

test_that("make_aggregated_time_series works", {
  this_data = get_senscape_data(key_path = "../../../auth/senscape_api_key.txt", start_datetime = lubridate::as_datetime("2023-03-07"), end_datetime = lubridate::as_datetime("2023-03-08"), deviceIds = c("5f1076c998fda900151ff683", "5f1076c998fda900151ff683", "5f10762e98fda900151ff680", "5f10767c98fda900151ff681", "5f1076ae98fda900151ff682")) %>% mutate(record_time = as_datetime(record_time), processed = as_datetime(processed), trap_ID = case_when(startsWith(client_name, "ASPB 1")~"ASPB 1", startsWith(client_name, "ASPB 2")~"ASPB 2", startsWith(client_name, "ASPB 3")~"ASPB 3", startsWith(client_name, "ASPB 4")~"ASPB 4", startsWith(client_name, "ASPB 5")~"ASPB 5")) %>% mutate(record_time_CET = with_tz(record_time, "CET"), processed_CET = with_tz(processed, "CET"), year = year(record_time_CET), hour = hour(record_time_CET), day = yday(record_time_CET), date_hour = floor_date(record_time_CET, unit = "hours"), date = as_date(record_time_CET), masked_lon = round_down(lng, cell_mask), masked_lat = round_down(lat, cell_mask),  TigacellID = paste(masked_lon, masked_lat, sep="_"))
  this_result = make_aggregated_time_series(this_data, classification = "Aedes female")
  expect_equal(nrow(this_result), 8)
})
