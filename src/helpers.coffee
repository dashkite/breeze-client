import * as Fn from "@dashkite/joy/function"
import * as P from "@dashkite/joy/predicate"
import * as Obj from "@dashkite/joy/object"
import * as k from "@dashkite/katana"
import * as m from "@dashkite/mercury"
import {confidential} from "panda-confidential"
import p from "./profile"
import * as r from "./resources"

{randomBytes, convert} = confidential()

# TODO if this fails, be sure to delete profile from idb
# TODO perhaps change terminology in breeze API
#      to use address instead of nickname

createProfile = k.test (P.negate p.exists),
  k.peek Fn.flow [
    p.create
    (profile) ->
      nickname: profile.address
      profile: profile.toJSON()
    r.Profiles.post
  ]

addIdentity = Fn.tee Fn.flow [
  k.push p.get
  k.poke (profile, token) ->
    nickname: profile.address
    token: token
  k.pop r.Identities.post
]

register = Fn.tee Fn.flow [
  createProfile
  addIdentity
]

authenticate = k.push (token) -> r.Authentication.post { token }

load = k.poke r.Authentication.parseProfile

getNickname = Fn.flow [
  p.get
  Obj.get "address"
]

fetchEntry = Fn.flow [
  k.push getNickname
  k.mpoke (nickname, tag) -> { nickname, tag }
  k.poke r.Entries.get
  k.poke ([entry]) -> entry
]

readEntry = k.poke Fn.flow [
  r.Entry.get
  Obj.get "content"
]

addEntry = Fn.flow [
  k.push getNickname
  k.poke (nickname, context) -> Obj.merge context, {nickname}
  k.poke r.Entries.post
  k.mpoke ({nickname, id}, {tag}) ->  { nickname, id, tag }
  k.pop r.Tag.put
]

export {
  authenticate, load, register
  fetchEntry, readEntry, addEntry
}
