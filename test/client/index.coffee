import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import "@dashkite/breeze-client"
import Zinc from "@dashkite/zinc"
import { Profile } from "../../src/resources"

window.__ready = false

window.__describe = (description) ->
  if !description.remote.profile
    console.log "setup: deleting remote breeze profile"
    profile = await Zinc.getAdjunct "breeze-development-api.dashkite.com"
    await Profile.delete
      authority: "breeze-development-api.dashkite.com"
      nickname: profile.address
  if !description.local.breeze
    console.log "setup: deleting local breeze profile"
    profile = await Zinc.getAdjunct "breeze-development-api.dashkite.com"
    await profile.delete()
  if !description.local.app
    console.log "setup: deleting local app profile"
    profile = await Zinc.current
    await profile.delete()
  window.__ready = true

window.addEventListener "DOMContentLoaded", ->

  console.log "application loaded"

  document
    .querySelector "body > p"
    .textContent = window.location.href

  document
    .querySelector "breeze-connect"
    .addEventListener "success", ->
      console.log "success!"
      window.__profile = await Zinc.current
      window.__success = window.__profile?
      