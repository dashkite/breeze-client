import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import "@dashkite/breeze-client"
import Zinc from "@dashkite/zinc"
import { Profile, Identities, Identity, Entries, Entry } from "../../src/resources"

window.env = mode: "development"

window.__ready = false

window.__describe = (description) ->

  profile = await Zinc.getAdjunct "breeze-development-api.dashkite.com"

  try
    if !description.remote.id
      console.log "setup: deleting remote breeze identities"
      identities = await Identities.get
        authority: "breeze-development-api.dashkite.com"
        nickname: profile.address
      for identity in identities
        await Identity.delete
          authority: "breeze-development-api.dashkite.com"
          nickname: profile.address
          id: identity.id

  try
    if !description.remote.entry 
      console.log "setup: deleting remote breeze entries"
      entries = await Entries.get
        authority: "breeze-development-api.dashkite.com"
        nickname: profile.address
        tag: "test-api.dashkite.com"
      for entry in entries
        await Entry.delete
          authority: "breeze-development-api.dashkite.com"
          nickname: profile.address
          id: entry.id

  try
    if !description.remote.profile
      console.log "setup: deleting remote breeze profile"
      await Profile.delete
        authority: "breeze-development-api.dashkite.com"
        nickname: profile.address


  profile = await Zinc.current

  try
    if !description.local.breeze
      console.log "setup: deleting local breeze profile"
      await profile.delete()

  try
    if !description.local.app
      console.log "setup: deleting local app profile"
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
      