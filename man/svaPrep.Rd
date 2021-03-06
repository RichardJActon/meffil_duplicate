% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ewas.r
\name{svaPrep}
\alias{svaPrep}
\title{svaPrep}
\usage{
svaPrep(variable, covariates, beta.sva, featureset, most.variable)
}
\arguments{
\item{variable}{Independent variable vector.}

\item{covariates}{Covariates data frame to include in regression model,
one row per sample, one column per covariate (Default: NULL).}

\item{beta.sva}{Methylation levels matrix, one row per CpG site, one column per sample.}

\item{featureset}{Name from \code{\link{meffil.list.featuresets}()}  (Default: NA).
one row per sample, one column per covariate (Default: NULL).}

\item{most.variable}{Apply (Independent) Surrogate Variable Analysis to the 
given most variable CpG sites (Default: 50000).}
}
\description{
prepare data for sva and/or isva analysis
}
