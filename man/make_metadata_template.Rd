% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make_metadata_template.R
\name{make_metadata_template}
\alias{make_metadata_template}
\title{Make metadata template ready for data portal}
\usage{
make_metadata_template(
  type = "Dataset",
  name = "",
  description = "",
  conditions_of_access = "",
  url = "",
  same_as = "",
  identifier = "",
  license = "",
  citation = "",
  measurement_technique = "",
  temporal_coverage = "",
  creator = "",
  variable_info = "",
  distribution = ""
)
}
\arguments{
\item{type}{A string.}

\item{name}{A string.}

\item{description}{A string}

\item{conditions_of_access}{A string}

\item{url}{A string}

\item{same_as}{A string}

\item{identifier}{A string}

\item{license}{A string}

\item{citation}{A string}

\item{measurement_technique}{A string}

\item{temporal_coverage}{A string}

\item{creator}{A string}

\item{variable_info}{A string}

\item{distribution}{A string}
}
\value{
A json string.
}
\description{
Make metadata template ready for data portal
}
