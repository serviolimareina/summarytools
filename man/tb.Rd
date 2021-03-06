% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tb.R
\name{tb}
\alias{tb}
\title{Convert Summarytools Objects to Tibbles}
\usage{
tb(x, order = 1)
}
\arguments{
\item{x}{a freq() or descr() output object}

\item{order}{Integer. Useful for grouped results (produced with `stby()`)
only. When \code{1} (default), the levels of the grouping variable are used 
to sort the table, followed by the values of the second column (data values
for `freq()`, variable names for `descr()`. When \code{2}, the order is 
based on the second column first. In `freq()` tables, the row for \code{NA} 
counts will always appear last.}
}
\value{
A \code{\link[tibble]{tibble}} which is constructed following the 
\emph{tidy} principles.
}
\description{
Make a tidy dataset out of freq() or descr() outputs
}
