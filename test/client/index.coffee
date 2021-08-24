import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import "@dashkite/breeze-client"
import Profile from "@dashkite/zinc"

do ->
  console.log "application loaded"
  document
    .querySelector "breeze-connect"
    .addEventListener "success", ->
      console.log "success!"
      window.__profile = await Profile.current
      window.__success = window.__profile?