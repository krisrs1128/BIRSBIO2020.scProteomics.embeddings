% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/processing.R
\name{entropies}
\alias{entropies}
\title{Cluster Entropy of Subgraphs}
\usage{
entropies(G, clusters_)
}
\arguments{
\item{G}{A graph whose subgraphs we want to find.}

\item{clusters_}{The cluster membership of each cell. Indices must correspond
to indices of V(G).}
}
\description{
How much variation in cluster memberships does each subgraph have?
}
