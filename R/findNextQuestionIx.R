#' A facade for mirtCAT used by pilrContentApi()
#'
#' findNextQuestionIx() is the function used by pilrContentApi().
#'
#' buildMirtCatStateObject() is an internal function that is useful for tuning the survey. It returns the CATDesign parmeter required by
#' mirtCAT::findNextItem().
#'
#' TUNING EXAMPLE
#'
#' Simulate asking questions 1, 40 and 3 with responses always option 2.  Examine resulting state's theta history
#'
#'   > library(mirtCAT)
#'   > source('~/Projects/EDCAT/R/findNextQuestionIx.R')
#'   > x <- buildMirtCatStateObject(questions=c(1, 40, 3), answers=c(2, 2, 2))
#'   > x$person$thetas_history
#'   F1            F2        F3
#'   [1,] 0.0000000  0.000000e+00 0.0000000
#'   [2,] 0.1611487 -3.615848e-07 0.9306835
#'
#' Look at ?mirtCAT::findNext for examples of how to modify buildMirtCatStateObject()
#'
#' DATA FILES
#'
#' The data/<survey>/ files were extracted from MultiCATinput_EPSI_09-21-18.RData from the demo
#' Shiny app as follows:
#'
#'   load("MultiCATinput_EPSI_09-21-18.RData")
#'   epsi <- list(mo=mmod3, options=options, 
#'                design=list(min_SEM = 0.5), 
#'                start_item = 'Trule',
#'                df <- data.frame(Question = as.vector(questions), 
#'                                 Option = options, 
#'                                 Type = "radio", 
#'                                 stringsAsFactors = F)
#'                preCAT = list(min_items = 15, 
#'                             max_items = length(questions),
#'                             method = 'MAP',
#'                             criteria = 'Trule',
#'                             response_variance = T))
#'  save(epsi, file='data/epsi.RData')
#'
#' This changes makes it more obvious what variables are being set.
#' They are loaded by the survey.defintion() function

#' Calculate next question to ask
#'
#'
#' @param questionsAsked is a vector of the indicies of the questions answered so far
#' @param answers is a vector of the responses to corresponding questions
#' @param maxQuestions is for debugging. It causes findNextQuestion to pretend that mirtCAT terminated the test
#'                     after answering this many questions.
#' @param survey is the name of thed data subdirecory containing RDS files defining the survey
#' @return index of the next question to ask
#'e
#' @import mirtCAT
#' @export
findNextQuestionIx <- function(questionsAsked, answers, maxQuestions = 10000, survey = 'epsi') {
  mcState <- buildMirtCatStateObject(questionsAsked, answers, survey)
  tryCatch({
    if (mcState$design@stop_now || length(questionsAsked) >= maxQuestions) {
      list(questionIx=NA,
           extraValues=buildExtraValues(mcState))
    } else {
      ix <- findNextItem(mcState)
      list(questionIx=ix,
           questionInfo=survey.defintition(survey)$df[ix,],
           extraValues=list())
    }
  },
  error = function(err) {
    str(err)
    # will get error if there are no more questions. Treat as if it terminated cleanly
    list(questionIx=NA,
         extraValues=buildExtraValues(mcState))
  })
}

#' Construct the object that enapsulate the state of mirtCAT survey from responses so far
#'
#' @param questionsAsked is a vector of the indicies of the questions that have been answered
#'
#' @paaram answers is a vector of the indicies of the responses
#'
#' @return the state object x such that mirtCAT::findNextItem(x) returns the next question to be asked.
#'
buildMirtCatStateObject <- function(questionsAsked, answers, survey = 'idas') {
  sd <- survey.defintition(survey)
  CATdesign <- mirtCAT(sd$df, sd$mo,
                       preCAT = sd$preCAT,
                       design = sd$design,
                       start_item = sd$start_item,
                       design_elements = TRUE)
  if (is.null(questionsAsked)) {
    return(CATdesign)
  }
  for (i in c(1:length(questionsAsked))) {
    CATdesign <- updateDesign(CATdesign, items=questionsAsked[i], responses=answers[i])

    # NOTE: newer, broken mirtCAT changed param names:
    # CATdesign <- updateDesign(CATdesign, new_item=questionsAsked[i], new_response=answers[i])

    # from Server.R#166...

    CATdesign$design@Update.thetas(design=CATdesign$design, person=CATdesign$person, test=CATdesign$test)
    CATdesign$person$Update.info_mats(design=CATdesign$design, test=CATdesign$test)
    CATdesign$design <- mirtCAT:::Update.stop_now(CATdesign$design, person=CATdesign$person)
    CATdesign$design <- mirtCAT:::Next.stage(CATdesign$design, person=CATdesign$person, test=CATdesign$test, item=i)
  }
  CATdesign
}

buildExtraValues <- function(mcState) {
  terminatedOK <- if (mcState$design@stop_now) 'yes' else 'no'
  thetas <- unname(mcState$person$thetas[1,])
  SE_thetas <- unname(mcState$person$thetas_SE_history[nrow(mcState$person$thetas_SE_history),])
  list(
    list(question_code='terminated_successfully',
         question_type='q_yesno',
         response= terminatedOK,
         response_value=terminatedOK),
    list(question_code='thetas',
         question_type='numbers',
         responses= as.character(thetas),
         response_values=thetas),
    list(question_code='SE_thetas',
         question_type='numbers',
         responses= as.character(SE_thetas),
         response_values=SE_thetas)
  )
}

# Run the original, shiny version of same test with the same input parameters
#' @export
shiningPath <- function(survey = 'epsi') {
  GUI = list(title = "Shiny Survey",
             authors = "",
             stem_default_format = shiny::h5,
             lastpage = function(person){return(list(h5("Thanks for taking the survey.
                                                      To exit, please click the action button")))},
             time_before_answer = 3 # minimum amount of time for answering
  )
  sd <- survey.defintition(survey)
  mirtCAT(sd$df, sd$mo,
          preCAT = sd$preCAT,
          design = sd$design,
          start_item = sd$start_item,
          shinyGUI = GUI)
}

# Create a function to load the data that defines a survey from a specified data directory.
#
.build.survey.definition.fn = function() {
  loaded.survey <- ''
  survey.def <- NULL

  function(survey) {
    survey = unlist(survey)
    if (loaded.survey != survey) {
      print(paste('loading survey:', survey))
      data(list=survey, envir = environment())
      survey.def <<- get(survey)
      loaded.survey <<- survey
    }
    survey.def
  }
}
# Load the data that defines a survey from a specified data directory
# Uses a builder function so it can cache its result privately.
# @param survey is the name of the data subdirectory.
survey.defintition <- .build.survey.definition.fn()
