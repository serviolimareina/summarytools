# Arguments validation for freq, ctable, descr and dfSummary functions.
# Another function for validating st_options arguments follows.
#' @importFrom checkmate test_int test_logical test_choice test_string
#' @importFrom dplyr n_distinct
#' @keywords internal
check_arguments <- function(mc, dotArgs) {
  
  caller <- as.character(sys.call(-1))[1]
  pf <- parent.frame()
  errmsg <- character()
  
  # Deprecated arguments -------------------------------------------------------
  if ("file" %in% names(dotArgs)) {
    message(paste("'file' argument is deprecated; use with print() or view(),",
              "e.g. print(x, file=", dotArgs$file))
  }
  
  if ("omit.headings" %in% names(dotArgs)) {
    message(paste0("'omit.headings' argument has been replaced by 'headings'; ",
               "setting headings = ", 
               !isTRUE(dotArgs$omit.headings)))
    assign(x = "headings", value = !isTRUE(dotArgs$omit.headings), 
           envir = parent.frame())
  }
  
  
  # Arguments common to all functions ------------------------------------------
  
  if ("round.digits" %in% names(mc) && 
      !isTRUE(test_int(pf$round.digits))) {
    errmsg %+=% "'round.digits' must be a whole number"
  }
  
  if ("style" %in% names(mc)) {
    if (caller %in% c("freq", "descr", "ctable")) {
      if (!isTRUE(test_choice(pf$style, 
                              c("simple", "grid", "rmarkdown")))) {
        errmsg %+=% "'style' must be one of 'simple', 'grid', or 'rmarkdown'"
      }
    }
  }
  
  if ("plain.ascii" %in% names(mc) && 
      !isTRUE(test_logical(pf$plain.ascii, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'plain.ascii' must be either TRUE or FALSE"
  }
  
  if ("justify" %in% names(mc)) {
    if (caller == "freq") {
      if (!isTRUE(test_string(pf$justify, min.chars = 1)) ||
          !isTRUE(test_choice(substr(pf$justify,1,1), 
                              c("l", "c", "m", "r", "d")))) {
        errmsg %+=% "'justify' must be one of 'l', 'c', 'r', or 'd' (default)"
      }
    } else if (!isTRUE(test_choice(pf$justify, 
                                   c("l", "c", "m", "r")))) {
      errmsg %+=% "'justify' must be one of 'l', 'c', 'r'"
    }
    
    justify <- switch(substring(pf$justify, 1, 1),
                      l = "left",
                      c = "center",
                      m = "center",
                      d = "default",
                      r = "right")
    
    assign("justify", justify, parent.frame())
  }
  
  if ("display.labels" %in% names(mc) &&
      !isTRUE(test_logical(pf$display.labels, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'display.labels' must be either TRUE or FALSE"
  }
  
  if ("headings" %in% names(mc) &&
      !isTRUE(test_logical(pf$headings, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'headings' must be either be TRUE or FALSE"
  }
  
  # freq-specific arguments ----------------------------------------------------
  if (caller == "freq") {
    
    if ("report.nas" %in% names(mc) && 
        !isTRUE(test_logical(pf$report.nas, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'report.nas' must be either TRUE or FALSE"
    }
    
    if ("display.type" %in% names(mc) &&
        !isTRUE(test_logical(pf$display.type, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'display.type' must be either TRUE or FALSE"
    }
    
    if ("cumul" %in% names(mc) && 
        !isTRUE(test_logical(pf$cumul, len = 1, any.missing = FALSE))) {
      errmsg %+=% "'cumul' must be either TRUE or FALSE"
    }
    
    if ("order" %in% names(mc)) {
      order <- switch(tolower(substring(sub("[+-]", "", pf$order), 1, 1)),
                      d = "default",
                      l = "levels",
                      f = "freq",
                      n = "names")
      
      if (!isTRUE(test_choice(order, 
                              c("default", "levels", "freq", "names")))) {
        errmsg %+=% paste("'order' must be one of 'default', 'levels',",
                          "'freq', or 'names'")
      } else if (order == "levels" && !is.factor(pf$x)) {
        errmsg %+=% paste("'order' can be set to 'factor' only for factors.",
                          "Use 'names' or 'freq', or convert object to factor",
                          "prior to calling freq()")
      }
      
      order_sign <- sub("^.*([-+]).*$", "\\1", pf$order)
      order_sign <- ifelse(order_sign %in% c("+", "-"), order_sign, "+")
      
      assign("order", order, envir = parent.frame())
      assign("order_sign", order_sign, envir = parent.frame())
    } else {
      assign("order_sign", "+", envir = parent.frame())
    }
    
    if ("rows" %in% names(mc)) {
      
      if (NA %in% pf$rows) {
        errmsg %+=% paste("'rows' cannot contain NA; NA's are always displayed",
                          "last; use 'report.nas' to turn off na reporting")
      }
      
      if (is.character(pf$rows) && length(pf$rows) > 1 &&
          !all(pf$rows %in% unique(pf$x))) {
        errmsg %+=% paste("the following items used in the 'rows' argument",
                          "are not found in the data:", 
                          paste(setdiff(pf$rows, unique(pf$x)), sep = ","))
      }
      
      if (is.numeric(pf$rows) && length(pf$rows) > 0) {
        if (0 %in% pf$rows || length(unique(sign(pf$rows))) > 1) {
            errmsg %+=% "Invalid 'rows' argument"
        } else if (abs(max(pf$rows)) >= n_distinct(pf$x)) {
          nmax <- n_distinct(pf$x) - 1
          rows <- pf$rows[-which(abs(pf$rows) > nmax)]
          if (length(rows) > 0) {
            message("There are only ", nmax, " rows to show; higher ",
                    "numbers will be ignored")
            assign("rows", rows, envir = parent.frame())
          } else {
            errmsg %+=% "Invalid 'rows' argument"
          }
        }
      }
    }
  }
  
  # freq & ctable arguments ----------------------------------------------------
  if (caller %in% c("freq", "ctable")) {
    if ("totals" %in% names(mc) && 
        !isTRUE(test_logical(pf$totals, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'totals' must be either TRUE or FALSE"
    }
    
    if (!identical(pf$weights, NA)) {
      if (is.null(pf$weights)) {
        errmsg %+=% "weights vector not found"
      } else if (length(pf$weights) != nrow(as.data.frame(pf$x))) {
        errmsg %+=% "weights vector must have same length as 'x'"      
      }
    }
  }
  
  # freq & descr arguments -----------------------------------------------------
  if (caller %in% c("freq", "descr")) {
    if ("rescale.weights" %in% names(mc) &&
        !isTRUE(test_logical(pf$rescale.weights, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'rescale.weights' must be either TRUE or FALSE"
    }
  }
  
  # ctable-specific arguments --------------------------------------------------
  if (caller == "ctable") {
    if ("prop" %in% names(mc)) {
      prop <- tolower(substr(pf$prop, 1, 1))
      if(!isTRUE(test_choice(prop, c("t", "r", "c", "n")))) {
        errmsg %+=% "'prop' must be one of 't', 'r', 'c', or 'n'"
      }
      if (nchar(prop > 1)) {
        assign("prop", prop, envir = parent.frame())
      }
    }
    
    if ("useNA" %in% names(mc) &&
        !isTRUE(test_choice(pf$useNA, 
                            c("ifany", "always", "no")))) {
      errmsg %+=% "'useNA' must be one of 'ifany', 'always', or 'no'"
    }
    
    if ("dnn" %in% names(mc) &&
        !isTRUE(test_character(pf$dnn, any.missing = FALSE, 
                               len = 2, unique = TRUE))) {
      errmsg %+=% "'dnn' must be a character vector of 2 distinct values"
    }
  }
  
  # descr arguments ------------------------------------------------------------
  if (caller == "descr") {
    if ("na.rm" %in% names(mc) &&
        !isTRUE(test_logical(pf$na.rm, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'na.rm' must be either TRUE or FALSE"
    }
    
    if ("transpose" %in% names(mc) &&
        !isTRUE(test_logical(pf$transpose))) {
      errmsg %+=% "'transpose' must be either TRUE or FALSE"
    }

    if (!identical(pf$weights, NA)) {
      if (is.null(pf$weights)) {
        errmsg %+=% "weights vector not found"
      } else if (length(pf$weights) != nrow(pf$x.df)) {
        errmsg %+=% "weights vector must have same length as 'x'"      
      }
    }
  }

    
  # dfSummary arguments --------------------------------------------------------
  if (caller == "dfSummary") {
    
    if (!isTRUE(test_choice(pf$style, c("grid", "multiline")))) {
      errmsg %+=% "'style' must be either 'grid' or 'multiline'"
    }

    if ("varnumbers" %in% names(mc) &&
        !isTRUE(test_logical(pf$varnumbers, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'varnumbers' must be either TRUE or FALSE"
    }
    
    if ("labels.col" %in% names(mc) &&
        !isTRUE(test_logical(pf$labels.col, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'labels.col' must be either TRUE or FALSE"
    }
    
    if ("valid.col" %in% names(mc) &&
        !isTRUE(test_logical(pf$valid.col, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'valid.col' must be either TRUE or FALSE"
    }
    
    if ("na.col" %in% names(mc) &&
        !isTRUE(test_logical(pf$na.col, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'na.col' must be either TRUE or FALSE"
    }
    
    if ("graph.col" %in% names(mc) &&
        !isTRUE(test_logical(pf$graph.col, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'graph.col' must be either TRUE or FALSE"
    }
    
    if ("graph.magnif" %in% names(mc) && pf$graph.magnif <= 0) {
      errmsg %+=% "'graph.magnif' must be > 0"
    }
    
    if ("style" %in% names(mc) && pf$style == "rmarkdown") {
      message("'rmarkdown' style not supported - using 'multiline' instead")
      assign("style", "multiline", envir = parent.frame())
    }
    
    if ("trim.strings" %in% names(mc) &&
        !isTRUE(test_logical(pf$trim.strings, 
                             len = 1, any.missing = FALSE))) {
      errmsg %+=% "'trim.strings' must be either TRUE or FALSE"
    }
    
    if ("silent" %in% names(mc) &&
        !isTRUE(test_logical(pf$silent, len = 1, any.missing = FALSE))) {
      errmsg %+=% "'silent' must be either TRUE or FALSE"
    }
    
    if ("tmp.img.dir" %in% names(mc) &&
        (!isTRUE(test_character(pf$tmp.img.dir, min.chars = 1, len = 1)) ||
         nchar(pf$tmp.img.dir) > 5)) {
      errmsg %+=% "'tmp.img.dir' must have at least 1 and at most 5 characters"
    }
    
    if ("tmp.img.dir" %in% names(mc) && isTRUE(.st_env$noX11)) {
      message("'tmp.img.dir' will be ignored since system has no X11 ",
              "capabilities")
    }
  }
  
  # Order the messages according to arguments order
  # ord <- numeric()
  # for(a in names(mc)[-1]) {
  #   ord %+=% grep(pattern = a,
  #                 x = sub(pattern = "^'(.+?)'.+$", 
  #                         replacement = "\\1", x = errmsg, 
  #                         perl = TRUE), 
  #                 fixed = TRUE)
  # }
  #
  # return(errmsg[ord])
  return(errmsg)
}

# check_arguments_st_options ---------------------------------------------------
#' @importFrom checkmate test_int test_logical test_choice 
#' test_file_exists test_character
check_arguments_st_options <- function(mc) {
  
  pf <- parent.frame()
  errmsg <- character()
  
  if ("style" %in% names(mc)) {
    if (!isTRUE(test_choice(pf$style, 
                            c("simple", "grid", "rmarkdown")))) {
      errmsg %+=% paste("'style' must be one of 'simple', 'grid', or 'markdown';",
                     "See documentation for details")
    }
  }

  if ("round.digits" %in% names(mc) && !isTRUE(test_int(pf$round.digits))) {
    errmsg %+=% "'round.digits' must be a whole number"
  }
  
  if ("plain.ascii" %in% names(mc) && 
      !isTRUE(test_logical(pf$plain.ascii, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'plain.ascii' must be either TRUE or FALSE"
  }
  
  if ("headings" %in% names(mc) &&
      !isTRUE(test_logical(pf$headings, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'headings' must be either be TRUE or FALSE"
  }
  
  if ("footnote" %in% names(mc) &&
      !isTRUE(test_character(pf$footnote)) && !is.na(pf$footnote)) {
    errmsg %+=% "'footnote' must be either be a string or NA"
  }
  
  if ("display.labels" %in% names(mc) &&
      !isTRUE(test_logical(pf$display.labels, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'display.labels' must be either TRUE or FALSE"
  }
  
  if ("bootstrap.css" %in% names(mc) &&
      !isTRUE(test_logical(pf$bootstrap.css, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'bootstrap.css' must be either TRUE or FALSE"
  }
  
  if ("custom.css" %in% names(mc) && !is.na(pf$custom.css) &&
      !isTRUE(test_file_exists(pf$custom.css, access = "r"))) {
    errmsg %+=% "'custom.css' file not found"
  }
  
  if ("escape.pipe" %in% names(mc) &&
      !isTRUE(test_logical(pf$escape.pipe, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'escape.pipe' must be either TRUE or FALSE"
  }
  
  if ("freq.totals" %in% names(mc) &&
      !isTRUE(test_logical(pf$freq.totals, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'freq.totals' must be either TRUE or FALSE"
  }
  
  if ("freq.report.nas" %in% names(mc) &&
      !isTRUE(test_logical(pf$freq.report.nas, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'freq.report.nas' must be either TRUE or FALSE"
  }
  
  if ("ctable.prop" %in% names(mc) &&
      !isTRUE(test_choice(pf$ctable.prop, c("r", "c", "t", "n")))) {
    errmsg %+=% "'ctable.prop' must be one of \"r\", \"c\", \"t\", or \"n\""
  }
  
  if ("ctable.totals" %in% names(mc) &&
      !isTRUE(test_logical(pf$ctable.totals, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'ctable.totals' must be either TRUE or FALSE"
  }
  
  if ("descr_stats" %in% names(mc)) {
    valid_stats <- c("mean", "sd", "min", "q1", "med", "q3","max", "mad", 
                     "iqr", "cv", "skewness", "se.skewness", "kurtosis", 
                     "n.valid", "pct.valid")
    
    if (length(pf$descr_stats) == 1 && 
        !(pf$descr_stats %in% c("fivevnum", "common")) &&
        !(pf$descr_stats %in% valid_stats)) {
      errmsg %+=%
        paste("'descr_stats' value", dQuote(pf$descr_stats), "not recognized;",
              "allowed values are: ", 
              paste('"fivenum", "common", or a combination of :',
                    paste0(dQuote(valid_stats), sep = ", ")))
    }
  }
  
  if ("descr.transpose" %in% names(mc) &&
      !isTRUE(test_logical(pf$descr.transpose, len = 1, any.missing = FALSE))) {
    errmsg %+=% "'descr.transpose' must be either TRUE or FALSE"
  }
  
  if ("freq.totals" %in% names(mc) &&
      !isTRUE(test_logical(pf$freq.totals, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'freq.totals' must be either TRUE or FALSE"
  }
  
  if ("dfSummary.varnumbers" %in% names(mc) &&
      !isTRUE(test_logical(pf$dfSummary.varnumbers, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'dfSummary.varnumbers' must be either TRUE or FALSE"
  }
  
  if ("dfSummary.labels.col" %in% names(mc) &&
      !isTRUE(test_logical(pf$dfSummary.labels.col,
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'dfSummary.labels.col' must be either TRUE or FALSE"
  }
  if ("dfSummary.valid.col" %in% names(mc) &&
      !isTRUE(test_logical(pf$dfSummary.valid.col,
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'dfSummary.valid.col' must be either TRUE or FALSE"
  }
  if ("dfSummary.na.col" %in% names(mc) &&
      !isTRUE(test_logical(pf$dfSummary.na.col, 
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'dfSummary.na.col' must be either TRUE or FALSE"
  }
  
  if ("dfSummary.graph.col" %in% names(mc) &&
      !isTRUE(test_logical(pf$dfSummary.graph.col,
                           len = 1, any.missing = FALSE))) {
    errmsg %+=% "'dfSummary.graph.col' must be either TRUE or FALSE"
  }
  
  if ("dfSummary.graph.magnif" %in% names(mc) && 
      pf$dfSummary.graph.magnif <= 0) {
    errmsg %+=% "'dfSummary.graph.magnif' must be > 0"
  }
  
  if ("lang" %in% names(mc) && !pf$lang %in% 
      c(rownames(.translations), "custom")) {
    errmsg %+=% paste0("'lang' can take the following values only: ",
                       paste(rownames(.translations), collapse = ", "))
  }
  
  if ("tmp.img.dir" %in% names(mc) &&
      (!isTRUE(test_character(pf$tmp.img.dir, min.chars = 1, len = 1)) ||
       nchar(pf$tmp.img.dir) > 5)) {
    errmsg %+=% "'tmp.img.dir' must have at least 1 and at most 5 characters"
  }
  
  return(errmsg)
}
