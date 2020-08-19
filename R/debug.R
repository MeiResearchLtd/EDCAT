#' Simulate tests

findNextQuestionDF <- function(qs, as, survey) {
  lst <- findNextQuestionIx(qs, as, survey=survey)
  if (is.na(lst$questionIx)) {
    return(data.frame(ix=NA, Question='done'))
  }
  df <- lst$questionInfo
  df$ix <- lst$questionIx
  row.names(df) = NULL
  df[c('ix', 'Question')]
}

#' Simulate running the test using findNextQuestionIx
#' runtTest(3, survey='idas') will run findNextQuestionIx for the first 3 test questions choosing
#'                            response 1. It outputs the sequence of questions 
#' @param stepCount is number of questions to calculate
#' @param answers is a vector of response indices. It defaults to all 1s.
#' @parm survey is either 'epsi' or 'idas'.  Defaults to 'epsi'
#'                  
#' @export
runTest <- function (stepCount=1, answers =  c(rep(1,stepCount)), survey = 'epsi') {
  result = findNextQuestionDF(c(), c(), survey=survey)
  for (i in seq(stepCount)) {
    result[i+1,] = findNextQuestionDF(result$ix, answers[seq(i)], survey=survey)
    if (is.na(result[i+1,]$ix)) {
      break
    }
  }
  result$Resp = c(answers, NA)
  result
}

