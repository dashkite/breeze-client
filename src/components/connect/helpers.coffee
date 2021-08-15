import * as Fn from "@dashkite/joy/function"
import * as G from "@dashkite/joy/generic"
import * as Obj from "@dashkite/joy/object"
import * as T from "@dashkite/joy/type"
import * as It from "@dashkite/joy/iterable"
import * as Val from "@dashkite/joy/value"
import * as Ks from "@dashkite/katana/sync"
import * as K from "@dashkite/katana/async"
import * as R from "../../resources"
import * as C from "@dashkite/carbon"
import Profile from "@dashkite/zinc"
import * as Me from "@dashkite/mercury"

# Templates
import status from "./status"
import providers from "./providers"
import waiting from "./waiting"

attempt = Fn.curry (f, g) ->
  Fn.arity f.length, (args...) ->
    try
      await f.apply @, args
    catch error
      g error, args

hasStatus = Fn.curry (status, error) ->
  (T.isType Me.Error, error) && error.status == status

# TODO replace with Obj.fromEntries when avail
getParameters = ->
  r = {}
  for [ key, value ] from (new URL window.location).searchParams
    r[key] = value
  r

getAuthority = (mode) ->
  if mode == "production"
    "breeze-api.dashkite.com"
  else
    "breeze-#{mode}-api.dashkite.com"

initialize = Fn.flow [
  K.read "handle"
  K.peek (handle, description) ->
    Obj.assign handle.data, {
      description...
      token: getParameters().token
      authority: ( _authority = getAuthority description.mode ) 
      authorities: 
        breeze: _authority
        application: description.authority
      profiles:
        current: _current = await Profile.current
        application: undefined
        breeze: if _current? then await Profile.getAdjunct _authority
    }
]

action = (data) ->
  if data.profiles.application?
    "success"
  else
    if data.profiles.breeze?
      if data.entries?
        if data.entries > 0
          if data.profile.current?
            "reconcile entries"
          else
            "save entry as local profile"
        else
          if data.profile.current?
            "save local profile as entry"
          else
            "create default profile"
      else
        "get entries"
    else
      if data.token?
        "get breeze profile"
      else
        "get oauth token"


actions =

  "get oauth token": Fn.flow [
    C.render providers
  ]

  "get breeze profile": Fn.flow [
    K.poke R.Authentication.post
    K.push -> Profile.current
    K.read "data"
    K.peek (data, profile) -> data.profiles.breeze = profile
  ]

  "get entries": Fn.flow [
    K.push (data) ->
      authority: data.authorities.breeze
      nickname: data.profiles.breeze.address
      tag: data.authorities.application
    K.poke R.Entries.get
    K.peek (entries, data) ->
      data.entries = entries
  ]

  "create default profile": Fn.flow [
    K.push (data) ->
      Profile.createWithAddress data.authorities.application,
        data.profiles.breeze.address, {}
    K.push (profile, data) ->
      authority: data.authorities.breeze
      nickname: data.profiles.breeze.address
      displayName: data.displayName
      content: profile.toJSON()
    K.poke R.Entries.post
    K.push (entry, profile, data) ->
      authority: data.authorities.breeze
      nickname: entry.nickname
      id: entry.id
      tag: data.displayName
    K.pop R.Tag.put
    K.peek (entry, profile, data) ->
      data.profiles.application = profile
  ]

  "save local profile as entry": Fn.flow [
    -> console.log "save local profile as entry"
  ]

  "save entry as local profile": Fn.flow [
    -> console.log "save entry as local profile"
  ]
  
  "reconcile entries": Fn.flow [
    -> console.log "reconcile entries"
  ]
  "success": Fn.flow [
    -> console.log "success"
  ]

errors = do ->
  for action in actions
    generic
      name: action
      default: (error) -> throw error

handler = (action, predicate, f) ->
  generic errors[action], predicate, T.isArray, f

handler "get breeze profile", (hasStatus 404),
  K.peek (data) ->
    Obj.assign data,
      message: "Your token expired. Please login with your provider again."
      token: undefined

transition = Fn.flow [
  K.push action
  K.poke (name) -> attempt actions[name], errors[name]
  K.peek Fn.apply
]

redirect = Fn.pipe [
  Ks.push (target, event, handle) ->
    authority: handle.data.authorities.breeze
    service: target.name
    redirectURL: do ->
      _url = new URL window.location.href
      _url.searchParams.delete "token"
      _url.toString()

  Fn.flow [
    C.render waiting
    K.push R.OAuth.get
    K.peek (url) -> window.location.replace url
  ]
]

export {
  initialize
  transition
  redirect
}