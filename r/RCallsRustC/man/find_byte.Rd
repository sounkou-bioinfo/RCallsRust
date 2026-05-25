\name{find_byte}
\alias{find_byte}
\title{Find byte occurrences}
\usage{find_byte(x, needle = as.raw(0x41))}
\arguments{\item{x}{A raw vector.}\item{needle}{A scalar raw or integer in \code{[0, 255]}.}}
\value{A data frame with zero-based \code{position} and integer \code{byte} columns.}
\description{Find byte occurrences.}
