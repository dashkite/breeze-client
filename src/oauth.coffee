import {curry, binary, tee, flow} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import * as m from "@dashkite/mercury"
import {confidential} from "panda-confidential"
import p from "./profile"
import * as r from "./resources"
import * as h from "./helpers"

{randomBytes, convert} = confidential()

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
  k.push p.get
  k.poke (profile, token) ->
    nickname: profile.address
    token: token
  k.pop r.Identities.post
]

register = tee flow [
  createProfile
  addIdentity
]

authenticate = k.push (token) -> r.Authentication.post { token }

load = k.poke r.Authentication.parseProfile

getNickname = flow [
  p.get
  h.get "address"
]

fetchEntry = flow [
  k.push getNickname
  k.mpoke (nickname, tag) -> { nickname, tag }
  k.poke r.Entries.get
  k.poke ([entry]) -> entry
]

readEntry = k.poke flow [
  r.Entry.get
  h.get "content"
]

addEntry = flow [
  k.push getNickname
  k.poke (nickname, context) -> h.merge context, {nickname}
  k.poke r.Entries.post
  k.mpoke ({nickname, id}, {tag}) ->  { nickname, id, tag }
  k.pop r.Tag.put
]

export {
  authenticate, load, register
  fetchEntry, readEntry, addEntry
}
