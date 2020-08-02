import {curry, tee, flow} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import p from "./profile"
import * as r from "./resources"
import * as h from "./helpers"

getParameters = ->
  parameters = new URLSearchParams window.location.hash[1..]
  Object.fromEntries parameters.entries()

register = curry (tag, description, json) ->
  k.stack flow [
    # first, create the breeze profile if it doesn't exist
    # TODO if this fails, be sure to delete profile from idb
    # TODO perhaps change terminology in breeze API
    #      to use address instead of nickname
    k.test (h.not p.exists),
      k.peek flow [
        p.create
        (profile) ->
          nickname: profile.address
          profile: profile.toJSON()
        r.Profiles.post
      ]
    # next use the redirect query parameters to create an identity
    tee flow [
      k.push p.get
      k.push getParameters
      k.peek flow [
        ({access_token}, {nickname}) ->
          nickname: profile.nickname
          metadata: {access_token}
          service: "google"
          displayName: "Google Login"
        r.Identities.post
      ] ]
    # add the entry based on the fn arguments
    k.peek flow [
      p.get
      h.get "nickname"
      (content, nickname) ->
        { content: json, nickname, displayName: description }
      r.Entries.post
      ({nickname, id}) -> { nickname, id, tag }
      r.Tag.put
    ]
  ]

authenticate = (tag) ->
  flow [
    # use the redirect query paramters to create auth request
    getParameters
    ({access_token}) ->
      metadata: {access_token}
      service: "google"
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
