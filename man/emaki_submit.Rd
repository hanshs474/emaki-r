\name{emaki_submit}
\alias{emaki_submit}
\alias{emaki_status}
\alias{emaki_credits}
\title{Submit a run, look it up, read your credits}
\usage{
emaki_submit(prompt, model = "seedance_2_5", parameters = NULL, api_key = NULL, post = emaki_post)
emaki_status(id, api_key = NULL, post = emaki_post)
emaki_credits(api_key = NULL, post = emaki_post)
}
\arguments{
\item{prompt}{What to generate.}
\item{model}{Model id, as in \code{\link{emaki_generate_video}}.}
\item{parameters}{A named list passed through as-is.}
\item{id}{The id returned by \code{emaki_submit}.}
\item{api_key}{Key from \url{https://emaki.ai/settings/apikeys}; defaults to EMAKI_API_KEY.}
\item{post}{The HTTP function; replaceable in tests.}
}
\value{\code{emaki_submit}: the run id. \code{emaki_status}: a list with \code{id}, \code{status}
("generating", "completed" or "failed"), \code{videoUrl} and \code{failureCode}.
\code{emaki_credits}: remaining credits as an integer (free to call).}
\description{Lower-level calls for submitting now and collecting later.}
\examples{
\dontrun{
id <- emaki_submit("a fox trotting through fresh snow")
emaki_status(id)$status
emaki_credits()
}
}
