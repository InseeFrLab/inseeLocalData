test_that("get_dataset works", {
  vcr::use_cassette("na5_b-entr_individuelle-geo2017REE2017-com-44115", {
    res <- get_dataset("GEO2017REE2017",
                         "NA5_B-ENTR_INDIVIDUELLE",
                         'all.all',
                         "COM",
                         "44115")

    expect_is(res, "list")
    expect_equal(as.character(res$source$jeu_donnees), "GEO2017REE2017")
    expect_equal(res$donnees$codgeo[1], "44115")
    expect_named(res, c("donnees", "liste_code", "info_zone", "source"))
    expect_is(res$donnees, "data.frame")
    expect_is(res$liste_code, "data.frame")
    expect_is(res$info_zone, "data.frame")
    expect_is(res$source, "data.frame")
    expect_equal(dim(res$donnees), c(18, 7))
  })
})
