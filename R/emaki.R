emaki_base <- function() getOption("emaki.base_url", "https://emaki.ai")
emaki_keys_url <- "https://emaki.ai/settings/apikeys"

# Every failure carries a class to branch on: emaki_auth, emaki_quota, emaki_plan,
# emaki_busy, emaki_rejected, emaki_validation, emaki_failed, emaki_timeout, emaki_other.
emaki_stop <- function(kind, msg, status = NA_integer_) {
  stop(structure(class = c(paste0("emaki_", kind), "emaki_error", "error", "condition"),
                 list(message = paste("emaki:", msg), call = NULL, status = status)))
}

emaki_classify <- function(status, body = NULL) {
  code <- if (is.list(body) && is.character(body$code)) body$code else ""
  if (status == 401) return("auth")
  if (status == 402) return("quota")
  if (status == 403) return("plan")
  if (status == 409) return("busy")
  if (code %in% c("content_cooldown", "content_blocked")) return("rejected")
  if (status == 400) return("validation")
  "other"
}

# POST a JSON body; returns list(status, body). Replaceable in tests via `post =`.
emaki_post <- function(path, body, key) {
  h <- new_handle()
  handle_setheaders(h, "Content-Type" = "application/json", Authorization = paste("Bearer", key),
                    "User-Agent" = "emaki-r/0.1.0")
  json <- if (length(body)) toJSON(body, auto_unbox = TRUE) else "{}"
  handle_setopt(h, timeout = 60, postfields = json)
  res <- curl_fetch_memory(paste0(emaki_base(), path), handle = h)
  parsed <- tryCatch(fromJSON(rawToChar(res$content), simplifyVector = FALSE), error = function(e) NULL)
  list(status = res$status_code, body = parsed)
}

emaki_key <- function(api_key) {
  key <- if (!is.null(api_key) && nzchar(api_key)) api_key else Sys.getenv("EMAKI_API_KEY")
  if (!nzchar(key)) emaki_stop("auth", paste("an API key is required; create one at", emaki_keys_url))
  key
}

emaki_call <- function(path, body, api_key, post) {
  r <- post(path, body, emaki_key(api_key))
  if (r$status >= 200 && r$status < 300 && is.list(r$body)) return(r$body)
  msg <- r$body$error
  if (is.null(msg)) msg <- r$body$message
  if (is.null(msg)) msg <- paste("HTTP", r$status)
  emaki_stop(emaki_classify(r$status, r$body), msg, r$status)
}

#' @export
emaki_submit <- function(prompt, model = "seedance_2_5", parameters = NULL, api_key = NULL,
                         post = emaki_post) {
  if (!is.character(prompt) || !nzchar(trimws(prompt))) emaki_stop("validation", "prompt is required")
  body <- list(prompt = prompt, model = model)
  if (length(parameters)) body$parameters <- parameters
  a <- emaki_call("/api/video/ai", body, api_key, post)
  if (is.null(a$data$id)) emaki_stop("other", "the service returned no id")
  a$data$id
}

#' @export
emaki_status <- function(id, api_key = NULL, post = emaki_post) {
  emaki_call("/api/video/status", list(videoId = id), api_key, post)$data
}

#' @export
emaki_credits <- function(api_key = NULL, post = emaki_post) {
  a <- emaki_call("/api/user/get-user-credits", list(), api_key, post)
  # This endpoint answers refusals with HTTP 200 and code -1.
  if (!identical(as.integer(a$code), 0L)) {
    msg <- if (is.null(a$message)) "request refused" else a$message
    emaki_stop(if (grepl("api key", tolower(msg), fixed = TRUE)) "auth" else "other", msg)
  }
  as.integer(a$data$remainingCredits)
}

emaki_wait <- function(id, api_key, poll_seconds, timeout_seconds, post) {
  deadline <- Sys.time() + timeout_seconds
  while (Sys.time() < deadline) {
    Sys.sleep(poll_seconds)
    d <- tryCatch(emaki_status(id, api_key, post), emaki_auth = function(e) stop(e),
                  error = function(e) NULL) # a dropped poll is not a failed run
    if (is.null(d)) next
    if (identical(d$status, "completed") && !is.null(d$videoUrl)) return(d$videoUrl)
    if (identical(d$status, "failed")) {
      emaki_stop("failed", paste0("the run failed (", if (is.null(d$failureCode)) "unknown" else d$failureCode, ")"))
    }
  }
  emaki_stop("timeout", "deadline passed; the run may still finish in your emaki library")
}

#' @export
emaki_generate_video <- function(prompt, model = "seedance_2_5", parameters = NULL, api_key = NULL,
                                 poll_seconds = 5, timeout_seconds = 900, post = emaki_post) {
  id <- emaki_submit(prompt, model, parameters, api_key, post)
  emaki_wait(id, api_key, poll_seconds, timeout_seconds, post)
}

#' @export
emaki_generate_image <- function(prompt, model = "nano_banana_2_lite", parameters = NULL, api_key = NULL,
                                 poll_seconds = 5, timeout_seconds = 900, post = emaki_post) {
  id <- emaki_submit(prompt, model, parameters, api_key, post)
  emaki_wait(id, api_key, poll_seconds, timeout_seconds, post)
}
