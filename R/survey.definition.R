DATA_FILE <- 'MultiCATinput_EPSI_IDAS_05-04-20'

#' Load survey data and package in a common survey definition structure
#' 
#' DATA_FILE is an RData file provided by KU. This version contains the following variablesi:
#' 
#'     mod_epsi, options_epsi, questions_epsi,
#'     mod_idas, options_idas, questions_idas
#'    
#' Returns a list that has all inputs to mirtCAT for the given survey. The list has the following names that
#' correspond to mirtCAT parameter names:
#' 
#'     mo, options, design, start_item, df, preCAT
#' 
.load.survey.definition <- function(survey) {
  data( list = DATA_FILE, envir = environment() )
  survey <- unlist(survey)
  questions <- as.vector(get(paste0('questions_', survey)))
  list(  mo = get(paste0('mod_', survey)), 
         options = get(paste0('options_', survey)), 
         design = list(min_SEM = 0.5), 
         start_item = 'Trule',
         df = data.frame( Question = questions, 
                          Option = get(paste0('options_', survey)), 
                          Type = "radio", 
                          stringsAsFactors = F),
         preCAT = list(min_items = 15, 
                      max_items = length(questions),
                      method = 'MAP',
                      criteria = 'Trule',
                      response_variance = T) )
}

#' Return a caching version of .loadSurveyDefinition
survey.defintition <- (function() {
  current.survey <- ''
  current.survey.definition <- NULL
  function(survey) {
    if (current.survey != survey) {
      print(paste('loading survey:', survey))
      current.survey.definition <<- .load.survey.definition(survey)
      current.survey <<- survey
    }
    current.survey.definition
  }
})()
