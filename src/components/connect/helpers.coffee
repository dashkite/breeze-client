import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
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

find = Fn.flip Fn.detach Array::find

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
      # we store these as objects because they're wrapped as proxies
      # once we assign them to the observed data property
      profiles:
        current: (_current = await Profile.current)?.toObject()
        application: undefined
        breeze: if _current?
          (await Profile.getAdjunct _authority).toObject()
    }
]

action = (data) ->
  if data.profiles.application?
    "success"
  else
    if data.profiles.breeze?
      if data.entries?
        if data.entries.length > 0
          if data.profiles.current?
            "reconcile entries"
          else
            "save entry as local profile"
        else
          if data.profiles.current?
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


_run = Fn.flow [
  K.peek (name) -> console.log "action: ", name
  K.poke (name) -> attempt actions[name], errors[name]
  # TODO add to Katana as K.apply
  (daisho) ->
    f = daisho.pop()
    f daisho
]

run = (name) ->
  Fn.flow [
    K.push Fn.wrap name
    _run
  ]

transition = Fn.flow [
  K.push action
  _run
]

actions =

  "get oauth token": Fn.flow [
    C.render providers
  ]

  "get breeze profile": Fn.flow [
    K.poke R.Authentication.post
    K.push -> Profile.current
    K.read "data"
    K.peek (data, profile) -> data.profiles.breeze = profile.toObject()
  ]

  "create breeze profile": Fn.flow [
    K.push (data) -> Profile.create data.authorities.breeze, {}
    # we need to set this in case there's no current profile
    K.peek (profile) -> Profile.current = profile
    K.poke (profile) -> profile.toObject()
    K.push (profile, data) ->
      authority: data.authorities.breeze
      nickname: profile.address
      profile: JSON.stringify profile
    K.pop R.Profiles.post
    K.push (profile, data) ->
      authority: data.authorities.breeze
      nickname: profile.address
      token: data.token
    K.pop R.Identities.post
    K.peek (profile, data) -> data.profiles.breeze = profile
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
    # store the profile as an object because it's wrapped as a proxy
    # once we assign it to the observed data property
    K.peek (profile, data) ->
      Profile.current = profile
      data.profiles.current = profile.toObject()
  ]

  "save local profile as entry": Fn.flow [
    K.push (data) ->
      authority: data.authorities.breeze
      nickname: data.profiles.breeze.address
      displayName: data.displayName
      # this needs a JSON string as the property
      content: JSON.stringify data.profiles.current
    K.poke R.Entries.post
    K.push (entry, data) ->
      authority: data.authorities.breeze
      nickname: entry.nickname
      id: entry.id
      tag: data.authorities.application
    K.pop R.Tag.put
    K.push Fn.wrap "success"
    _run
  ]

  "save entry as local profile": Fn.flow [
    K.push (data) ->
      for entry in data.entries
        if entry.nickname == data.profiles.breeze.address
          return entry
      throw new Error "no match found"
    K.push (entry, data) ->
      authority: data.authorities.breeze
      nickname: entry.nickname
      id: entry.id
    K.poke R.Entry.get
    K.push (entry) -> Profile.fromJSON entry.content
    K.peek (profile) -> Profile.current = profile
    K.push Fn.wrap "success"
    _run
  ]
  
  "reconcile entries": Fn.flow [
    K.push (data) ->
      _filter = (entry) -> entry.nickname == data.profiles.current.address
      find _filter, data.entries
    K.branch [
      [ T.isDefined, 
        Fn.flow [ K.discard, run "save entry as local profile" ] ]
      [ (Fn.wrap true),
        Fn.flow [ K.discard, run "save local profile as entry" ] ]
    ] 
  ]

  "success": Fn.flow [
    K.read "handle"
    K.peek (handle) -> handle.dispatch "success"
  ]

errors = do ->
  r = {}
  for _name, _handler of actions
    r[_name] = generic
      name: _name
      default: (error) -> throw error
  r

handler = (action, predicate, f) ->
  generic errors[action], predicate, T.isArray, (error, args) ->
    Fn.apply f, args

handler "get breeze profile", (hasStatus 403), Fn.flow [
  K.push Fn.wrap "create breeze profile"
  _run
]

handler "get breeze profile", (hasStatus 404),
  K.peek (data) ->
    Obj.assign data,
      message: "Your token expired. Please login with your provider again."
      token: undefined


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