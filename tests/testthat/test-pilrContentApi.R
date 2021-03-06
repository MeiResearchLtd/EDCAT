context('pilrContentAPI')

source('sample-parameters.R')
source('buildTestInputs.R')

library(mirtCAT)
data(CATDesign)

dummyMirtCatDf <-
  data.frame(Question = c('question 1', 'question 2', 'question 3'),
           Option.1 = c('0-q1.opt1', '0-q2.opt1', '0-q3.opt1'),
           Option.2 = c('1-q1.opt2', '1-q2.opt2', '1-q3.opt2'),
           Option.3 = c('2-q1.opt3', '2-q2.opt3', '2-q3.opt3'),
           Option.4 = c('3-q1.opt4', '3-q2.opt4', '3-q3.opt4'),
           stringsAsFactors = FALSE)
dummyMirtCatDf <- df

test_that("extracts questions and options correctly", {
  skip('fixme')
  answers <- NULL
  questions <- NULL
  dummyCompute <- function(qs, as) {
    questions <<- qs
    answers <<- as
    1
  }

  result <- pilrContentApi('myPt', resultsSoFar, sourceCard,
                             findNextFn = dummyCompute,
                             mirtCatDataFrame = dummyMirtCatDf)
  expect_equal(result$error, NULL)
  expect_equal(questions, c(2, 3, 4, 6))
  expect_equal(answers, c(20, 30, 40, 60))
})

test_that("returns Done card if  params.maxQuestions already asked", {
  calcContentCard <- sourceCard
  calcContentCard$data$args <- '{ "maxQuestions": 2 }'
  
  result <- pilrContentApi('myPt', resultsSoFar, calcContentCard)
  expect_equal(length(result$result), 1)
  expect_equal(result$result[[1]]$card_type, 'instruction')
})

test_that("returns correct question as a card", {
  skip('fixme')
  
  # expectedNextCalcContentCard <- sourceCard
  # expectedNextCalcContentCard$section <- 2
  opt.filter = grepl('Option.*', names(dummyMirtCatDf))
  for (i in 1:3) {
    expected.opts = lapply(list(1,2,3,4,5),
                           function (optix) {
                             list(value = paste(optix), name = dummyMirtCatDf[[i, paste0('Option.', optix)]])
                           })
    
    
    result <- pilrContentApi('myPt', resultsSoFar, sourceCard,
                             findNextFn = function(x,y) { i },
                             mirtCatDataFrame = dummyMirtCatDf)
    
    cards <- result$result
    expect_equal(length(cards), 2)
    
    calcuatedCard <- cards[[1]]

    expect_equal(calcuatedCard$section, sourceCard$section)
    expect_equal(calcuatedCard$card_type, 'q_select')
    expect_equal(calcuatedCard$data$title, dummyMirtCatDf$Question[[i]])
    expect_equal(calcuatedCard$data$text, '')
    expect_equal(calcuatedCard$data$required, TRUE)
    expect_equal(length(calcuatedCard$data$options), length(names(dummyMirtCatDf)[opt.filter]))
    for (optix in 1:length(calcuatedCard$data$options)) {
      expect_equal(calcuatedCard$data$options[[optix]]$value, paste(optix-1))
      expect_equal(calcuatedCard$data$options[[optix]]$text, substring(dummyMirtCatDf[[i, paste0('Option.', optix)]], 3))
    }
    
    expect_equal(cards[[2]]$card_type, sourceCard$card_type)
    expect_equal(cards[[2]]$section, sourceCard$section + 1)
    
   # expect_equal(nextCalcContentCard, expectedNextCalcContentCard)
  }
})

test_that("works with sample request", {
  source('sample-parameters2.R')
  result <- pilrContentApi('myPt', resultsSoFar, sourceCard)
})

sourceCard <- list(
  card_type = "calculated",
  section = 2L,
  data = list(
    code = "calc1",
    color = NULL,
    tags = list(),
    i_title = NULL,
    i_text = NULL,
    serviceUrl = "http://localhost:3000",
    args = NULL
  )
)
test_that("same results shiny version when no repsonses to mirtCAT questions so far", {
  responses <- buildResultsSoFar(
    list(`1` = list( event_type=c('notresponse', 'response', 'response', 'response'),
                     question_code=c('ignored1', 'mc:2', 'mc:3', 'mc:4'),
                     response_value=c(NA, '2', '3', '4'),
                     question_type=c('information', 'instruction', 'q_yesno', 'q_select_multiple'))) )
  result <- pilrContentApi('ignored', responses, sourceCard)
  expect_equal(length(result$result), 2)
  expect_equal(result$result[[1]]$data$code, 'mc:1')
  expect_equal(result$result[[1]]$data$title, ' I did not like how clothes fit the shape of my body')
  expect_equal(levels(result$result[[1]]$data$options$value), as.character(0:4))
})


buildResultsSoFar <- function(sections) {
  result <- sapply(sections, buildSection, simplify = FALSE)
  # names(result) = c(1:length(result))
  result
}
buildSection <- function(sectionItems) {
  structure(list(data = sectionItems), class = 'data.frame', row.names = c(NA, 4L))
}
