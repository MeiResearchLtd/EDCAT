#' Misc functions for testing & constructing PiLR dynamic content response.
#' Moved out of findNextQuestionIx.R to simplify the latter for sharing with Phil Chalmers


titleForQuestion <- function(questionIx, survey.def) {
  survey.def$df$Question[[questionIx]]
}

optionTextsForQuestion <- function(questionIx, survey.def) {
  survey.def$options[questionIx,]
}

questionIxMatching <- function(text, survey.def) {
  match(text, survey.def$df$Question)
}
