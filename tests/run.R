library(emaki)
classify <- emaki:::emaki_classify
queue <- list(); calls <- list()
fake <- function(path, body, key) {
  calls[[length(calls) + 1]] <<- list(path = path, body = body)
  r <- queue[[1]]; queue <<- queue[-1]; r
}
ok <- function(x) list(status = 200L, body = x)

queue <- list(ok(list(success = TRUE, data = list(id = "v1", status = "generating"))),
              ok(list(success = TRUE, data = list(id = "v1", status = "generating"))),
              ok(list(success = TRUE, data = list(id = "v1", status = "completed", videoUrl = "https://cdn.emaki.ai/v1.mp4"))))
url <- emaki_generate_video("a fox", parameters = list(duration = 6), api_key = "sk-x", poll_seconds = 0, post = fake)
stopifnot(url == "https://cdn.emaki.ai/v1.mp4", calls[[1]]$path == "/api/video/ai",
          calls[[1]]$body$model == "seedance_2_5", calls[[1]]$body$parameters$duration == 6,
          calls[[2]]$path == "/api/video/status", calls[[2]]$body$videoId == "v1")

calls <- list()
queue <- list(ok(list(success = TRUE, data = list(id = "i1", status = "generating"))),
              ok(list(success = TRUE, data = list(id = "i1", status = "completed", videoUrl = "https://cdn.emaki.ai/i1.png"))))
stopifnot(emaki_generate_image("a mug", api_key = "sk-x", poll_seconds = 0, post = fake) == "https://cdn.emaki.ai/i1.png",
          calls[[1]]$body$model == "nano_banana_2_lite", is.null(calls[[1]]$body$parameters))

queue <- list(ok(list(success = TRUE, data = list(id = "f1", status = "generating"))),
              ok(list(success = TRUE, data = list(id = "f1", status = "failed", failureCode = "provider_error"))))
e <- tryCatch(emaki_generate_video("x", api_key = "sk-x", poll_seconds = 0, post = fake), emaki_failed = function(e) e)
stopifnot(inherits(e, "emaki_failed"), grepl("provider_error", conditionMessage(e)))

cases <- list(list(401L, list(error = "Invalid API key. Create one at https://emaki.ai/settings/apikeys"), "auth"),
              list(402L, list(error = "Insufficient credits"), "quota"),
              list(403L, list(error = "This model requires a purchase"), "plan"),
              list(409L, list(error = "Video generation is already in progress"), "busy"),
              list(429L, list(error = "cooling down", code = "content_cooldown"), "rejected"),
              list(400L, list(error = "blocked", code = "content_blocked"), "rejected"),
              list(400L, list(error = "Missing required parameters: prompt and model"), "validation"),
              list(500L, list(error = "Internal error"), "other"))
for (c in cases) {
  queue <- list(list(status = c[[1]], body = c[[2]]))
  e <- tryCatch(emaki_submit("x", api_key = "sk-x", post = fake), emaki_error = function(e) e)
  stopifnot(inherits(e, paste0("emaki_", c[[3]])), e$status == c[[1]])
}

queue <- list(ok(list(code = 0L, message = "ok", data = list(remainingCredits = 42L, hasPurchasedCredits = FALSE))))
stopifnot(emaki_credits(api_key = "sk-x", post = fake) == 42L)
queue <- list(ok(list(code = -1L, message = "Invalid API key. Create one at https://emaki.ai/settings/apikeys")))
e <- tryCatch(emaki_credits(api_key = "sk-x", post = fake), emaki_error = function(e) e)
stopifnot(inherits(e, "emaki_auth"))

if (nzchar(Sys.getenv("EMAKI_LIVE"))) {
  n <- emaki_credits()
  stopifnot(is.integer(n))
  e <- tryCatch(emaki_submit("live check", "nano_banana_2_lite", api_key = "sk-wrong-key"), emaki_error = function(e) e)
  stopifnot(inherits(e, "emaki_auth"), e$status == 401)
  cat("live ok: credits read, wrong key -> emaki_auth\n")
}
cat("all tests passed\n")
