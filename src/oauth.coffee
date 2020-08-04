import {curry, binary, tee, flow} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import p from "./profile"
import * as r from "./resources"
import * as h from "./helpers"

# TODO if this fails, be sure to delete profile from idb
# TODO perhaps change terminology in breeze API
#      to use address instead of nickname
createProfile = k.test (h.not p.exists),
  k.peek flow [
    p.create
    (profile) ->
      nickname: profile.address
      profile: profile.toJSON()
    r.Profiles.post
  ]

addIdentity = tee flow [
  k.read "token"
  k.push p.get
  k.poke (profile, token) ->
    nickname: profile.address
    token: token
  k.pop r.Identities.post
]

addEntry = (tag, description) ->
  flow [
    k.read "content"
    k.push flow [
      p.get
      h.get "address"
    ]
    k.push (nickname, content) ->
      { content, nickname, displayName: description }
    k.peek flow [
      r.Entries.post
      ({nickname, id}) -> { nickname, id, tag }
      r.Tag.put
  ] ]

register = (tag, description) ->
  k.stack flow [
    createProfile
    addIdentity
    addEntry tag, description
  ]

authenticate = (tag) ->
  flow [
    (token) -> { token }
    r.Authentication.post
    h.get "account"
    # get the associate entry based on the fn arguments
    ({nickname}) -> { nickname, tag }
    r.Entries.get
    ([entry]) -> entry
    r.Entry.get
    h.get "content"
  ]

export {register, authenticate}
