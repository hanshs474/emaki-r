\name{emaki_generate_video}
\alias{emaki_generate_video}
\alias{emaki_generate_image}
\title{Generate a Seedance video or an image on emaki}
\usage{
emaki_generate_video(prompt, model = "seedance_2_5", parameters = NULL, api_key = NULL,
  poll_seconds = 5, timeout_seconds = 900, post = emaki_post)
emaki_generate_image(prompt, model = "nano_banana_2_lite", parameters = NULL, api_key = NULL,
  poll_seconds = 5, timeout_seconds = 900, post = emaki_post)
}
\arguments{
\item{prompt}{What to generate. For image to video, the motion.}
\item{model}{Model id: "seedance_2_5", "seedance_2", "seedance_2_fast", "seedance_2_mini", "minimax_h3", "veo_3_1"; images "nano_banana_2_lite", "nano_banana_2", "seedream_5_lite", "gpt_image_2".}
\item{parameters}{A named list passed through as-is, e.g. \code{list(duration = 8, resolution = "720p", aspect_ratio = "9:16", image = "https://...")}.}
\item{api_key}{Key from \url{https://emaki.ai/settings/apikeys}; defaults to the EMAKI_API_KEY environment variable.}
\item{poll_seconds}{How often the run is polled.}
\item{timeout_seconds}{Deadline for the whole call.}
\item{post}{The HTTP function; replaceable in tests.}
}
\value{The URL of the finished file.}
\description{Submits one run on emaki (\url{https://emaki.ai}), waits for it and returns the result URL.
Failures signal a condition of class \code{emaki_auth}, \code{emaki_quota}, \code{emaki_plan},
\code{emaki_busy}, \code{emaki_rejected}, \code{emaki_validation}, \code{emaki_failed},
\code{emaki_timeout} or \code{emaki_other}.}
\examples{
\dontrun{
emaki_generate_video("a paper lantern drifting down a night river",
                     parameters = list(duration = 8, resolution = "720p"))
emaki_generate_image("a ramen stall in the rain, neon reflections")
}
}
