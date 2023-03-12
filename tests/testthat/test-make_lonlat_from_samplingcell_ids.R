test_that("correct number of longitudes are extracted", {
    expect_equal(length(make_lonlat_from_samplingcell_ids(ids=c("2.15_41.35", "2.10_41.20"), type="lon")), 2)
})
