import {tee, flow} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import p from "./profile"
import * as r from "./resources"
import * as h from "./helpers"

getParamters = ->
  parameters = new URLSearchParams window.location.hash[1..]
  Object.fromEntries parameters.entries()

# TODO if this fails, be sure to delete profile from idb
# TODO perhaps change terminology in breeze API
#      to use address instead of nickname
create = k.test (h.not p.exists),
  k.peek flow [
    p.create
    (profile) ->
      nickname: profile.address
      profile: profile.toJSON()
    r.Profiles.post
  ]

register = tee flow [
  k.push p.get
  k.push getParameters
  k.push ({access_token}, {nickname}) ->
      nickname: profile.nickname
      metadata: {access_token}
      service: "google"
      displayName: "Google Login"
  k.peek r.Identities.post
]

store = (name, json) ->
  flow [
    k.push p.get
    k.push h.get "nickname"
    k.push (content, nickname) ->
      {content: json, nickname, displayName: name }
    k.push r.Entries.post
    k.push ({nickname, id}) -> {nickname, id, tag: "hype"}
    k.push r.Tag.put
  ]

authenticate = k.peek flow [
  hashParameters
  ({access_token}) ->
    metadata: {access_token}
    service: "google"
  r.Authentication.post
]

restore = (fromJSON) ->
  flow [
    k.push p.get
    k.poke ({nickname}) -> {nickname, tag: "hype"}
    k.poke r.Entries.get
    k.poke ([entry]) -> entry
    k.poke r.Entry.get
    k.poke h.get "content"
    k.poke fromJSON
  ]

register = (name, json) ->
  flow [
    create
    register
    store name, json
  ]

authenticate = (fromJSON) ->
  flow [
    authenticate
    restore fromJSON
  ]

export {register, authenticate}
