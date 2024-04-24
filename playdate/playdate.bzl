"""Public interface for the Playdate rules"""

load(
    "//playdate/internal:playdate_application.bzl",
    _playdate_application = "playdate_application",
)

playdate_application = _playdate_application
