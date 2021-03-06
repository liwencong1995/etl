context("etl")

## TODO: Rename context
## TODO: Add more tests

test_that("sqlite works", {
  cars_sqlite <- etl("mtcars")
  expect_s3_class(cars_sqlite, c("etl_mtcars", "etl", "src_sqlite", "src_sql"))
  expect_true(file.exists(find_schema(cars_sqlite)))
  expect_message(find_schema(cars, "my_crazy_schema", "etl"))
  expect_output(summary(cars_sqlite), "files")
  expect_message(cars_sqlite %>% etl_create(), "success")
  expect_message(cars_sqlite %>% etl_init(), "Loading SQL script")
  expect_message(
    cars_sqlite %>% etl_cleanup(delete_raw = TRUE, delete_load = TRUE),
    "Deleting files")
})

test_that("dplyr works", {
  expect_message(cars <- etl("mtcars") %>%
    etl_create(), regexp = "success")
  expect_gt(length(src_tbls(cars)), 0)
  tbl_cars <- cars %>%
     tbl("mtcars")
  expect_s3_class(tbl_cars, "tbl_sqlite")
  expect_s3_class(tbl_cars, "tbl_sql")
  res <- tbl_cars %>%
    collect()
  expect_equal(nrow(res), nrow(mtcars))
  # double up the data
  expect_message(
    cars %>%
      etl_update(), regexp = "success")
  res2 <- tbl_cars %>%
    collect()
  expect_equal(nrow(res2), 2 * nrow(mtcars))
})


test_that("mysql works", {
  if (require(RMySQL) && mysqlHasDefault()) {
    db <- src_mysql_cnf()
    expect_s3_class(db, "src_mysql")
    cars_mysql <- etl("mtcars", db = db)
    expect_s3_class(cars_mysql, c("etl_mtcars", "etl", "src_mysql", "src_sql"))
    expect_true(file.exists(find_schema(cars_mysql)))
    expect_message(find_schema(cars, "my_crazy_schema", "etl"))
    expect_output(summary(cars_mysql), "/tmp")
  }
})

test_that("MonetDBLite works", {
  if (require(MonetDBLite)) {
    db <- MonetDBLite::src_monetdblite()
    cars_monet <- etl("mtcars", db = db)
    expect_message(
      cars_monet %>%
        etl_create()
    )
    tbl_cars <- cars_monet %>%
      tbl("mtcars")
    expect_equal(nrow(tbl_cars %>% collect()), 32)
    expect_s3_class(cars_monet, "src_monetdb")
    expect_s3_class(tbl_cars, "tbl_monetdb")
  }
})

test_that("valid_year_month works", {
  expect_equal(
    nrow(valid_year_month(years = 1999:2001, months = c(1:3, 7))), 12)
  test_dir <- "~/dumps/airlines"
  # if (require(airlines) & require(etl) & dir.exists(test_dir)) {
  #   airlines <- etl("airlines", dir = test_dir) %>%
  #     etl_extract(year = 1987)
  #   expect_length(match_files_by_year_months(
  #     list.files(attr(airlines, "raw_dir")),
  #     pattern = "On_Time_On_Time_Performance_%Y_%m.zip",
  #     year = 1987), 3)
  #  }
})

test_that("extract_date_from_filename works", {
  test <- expand.grid(year = 1999:2001, month = c(1:6, 9)) %>%
    mutate(filename = paste0("myfile_", year, "_", month, ".ext"))
  expect_is(
    extract_date_from_filename(test$filename, pattern = "myfile_%Y_%m.ext"),
    "Date")
  expect_null(extract_date_from_filename(list.files("/cdrom"), pattern = "*"))
})

test_that("etl works", {
  expect_error(etl("willywonka"), "Please make sure that")
  expect_message(
    etl("mtcars", dir = file.path(tempdir(), "etltest")), "etltest")
  cars <- etl("mtcars")
  expect_true(is.etl(cars))
  expect_output(print(cars), "sqlite")
})

test_that("smart_download works", {
  cars <- etl("mtcars")
  urls <- c("http://www.google.com", "http://www.nytimes.com")
  expect_length(smart_download(cars, src = urls), 2)
})
