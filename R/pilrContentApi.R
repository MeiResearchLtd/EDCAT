##################################################################################
## A facade for computeQuestion that implements the PiL<R Calculated Content API
## for requests submitted by openCPU.
##
##################################################################################

#' Wrap PiLR Content API around a mirtCAT survey
#'
#' See "232 - KU Cat Design - Remote Calculation Card" (https://docs.google.com/document/d/1fC8kag54Ttm9Yy0vm3oayHKyk5jLnvHw9e5MOqrkZJo)
#'
#' @param participantCode not used here but part of API
#'
#' @param resultsSoFar the 'result' variable from EMA survey director.
#'   It defines the questions asked so far and the answers given
#'
#' @param sourceCard the calulated content card object that triggered this request. Only the properties listed below are
#'   used.
#'
#' @param sourceCard$section is used so set the section of the expansion cards
#'
#' @param sourceCard$args$maxQuestions is option for testing.  If set, pilrContentApi() will return the Done result
#' 
#' @param findNextFn is a hook for testing. Its default value invokes a facade for mirtCAT::findNext.
#' 
#' @mirtCatDataFrame is the 'df' parameter passed to mirtCAT::mirtCAT. It defines the questions and response options. 
#'
#' @return a list of cards objects with which EMA replaces the sourceCard in the survey
#'
#' @export
pilrContentApi <- function(participantCode, resultsSoFar, sourceCard,
                             # following parameters are test hooks.
                             findNextFn = findNextQuestionIx,
                             # unsused parameters from new AP
                             timestamp=NULL, currentSettings=NULL, securityToken=NULL, language=NULL,
                             ext=NULL,
                             ...unsused
                           ) {
  param <- buildParamFn(sourceCard$data$args)

  tryCatch({
    history <- buildHistory(resultsSoFar)

    # For testing
    # if(nrow(history) >= param('maxQuestions', 1e6)) {
    #   return(buildDoneResult(sourceCard$section))
    # }
    r <- findNextFn(history$questions, history$answers, param('maxQuestions', 1e6),
                    survey = param('survey', 'epsi'))
    nextQuestionIx <- r$questionIx

    if (!is.numeric(nextQuestionIx)) {
      # End of test: return DONE card & extra values 
      cards <- list(buildDoneCard(sourceCard$section))
      return(list( cards = cards,
                   result = cards,
                   extra_values = r$extraValues,
                   expiration_timestamp = timestamp ))
    }
    nextQuestionInfo <- r$questionInfo
    
    text <- if (as.logical(param('debug', FALSE))) {
      paste0('(question #', nextQuestionIx, ')') 
    } else {
      ''
    }
    calculatedCard <- buildSelectCard(nextQuestionIx, nextQuestionInfo, sourceCard$section, text) 
    nextCalcCard <- sourceCard
    nextCalcCard$section <- nextCalcCard$section + 1
    nextCalcCard$data$code <- paste0('after:', nextQuestionIx)
   
    # Return result compatible with both old & new api
    cards <- list(calculatedCard, nextCalcCard)
    list( result = cards,  # old expected property
          cards =  cards,  # new expected Property
          expiration_timestamp = timestamp
    ) 
    
  },
  error = function(error_condition) {
    list(error=as.character(error_condition))
  })
}

buildParamFn <- function(argString) {
  noParams <- function(paramName, defaultValue) defaultValue
  tryCatch({
    paramMap = jsonlite::parse_json(argString)
    if (is.list(paramMap)) {
       function(paramName, defaultValue) {
        if (exists(paramName, paramMap)) paramMap[paramName] else  defaultValue
      }
    } 
    else {
      noParams
    }
  }, error = function(error) noParams)
}

#' Extracts question and answer indices from resultsSoFar
buildHistory = function(resultsSoFar) {
  questions <- c()
  answers <- c()
  for (section in resultsSoFar) {
    filter <- grepl('mc:.*', section$data$question_code)
    qs = substring(section$data$question_code[filter], 4) # question ix is code with 'mc:' prefix removed
    as = section$data$response_value[filter]
    questions <- c(questions, as.numeric(qs))
    answers <- c(answers, as.numeric(as))
  }
  data.frame(questions, answers)
}

buildSelectCard <- function(questionIx, questionInfo, section, text) {
  list(card_type = 'q_select',
       section = section,
       order = 1,
       data = list(title = trimws(questionInfo$Question),
                   text = text,
                   code = paste0('mc:', questionIx),
                   required = TRUE,
                   options = optionListForQuestion(questionInfo)))
}

optionListForQuestion <- function(questionInfo) {
  # Convert mirtCAT options [dataframe columns named 'Option-0', etc] to card options
  text <- as.character(questionInfo[1, startsWith(colnames(questionInfo), "Option")])
  value <- as.character(0:(length(text) - 1))
  data.frame(text=text, value=value, order=value)
}

buildDoneCard <- function(section, title= 'Finished', text='Thank you! Please press submit to send results.') {
  list(card_type = 'instruction',
       section = section,
       order = 1,
       data = list(title = title,
                   text = text,
                   code = paste0('mc:done')))
}

# dump inputs passed by openCPU for use in sample-parameters.R for testing
#' @export
dumperOld <- function(participantCode, resultsSoFar, sourceCard, 
                      timestamp=NULL, currentSettings=NULL, securityToken=NULL, language=NULL,
                      ext=NULL,
                      ...unused) {
  fn <- 'dumped-stuff.R'
  dump(c('participantCode', 'resultsSoFar', 'sourceCard', 
         'timestamp', 'currentSettings', 'securityToken', 'language',
         'ext', 'unused'), 
       file=fn)
  readChar(fn, file.info(fn)$size)
}
