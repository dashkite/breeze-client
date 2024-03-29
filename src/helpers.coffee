import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
import * as Obj from "@dashkite/joy/object"
import * as T from "@dashkite/joy/type"
import * as It from "@dashkite/joy/iterable"
import * as Val from "@dashkite/joy/value"
import * as Ks from "@dashkite/katana/sync"
import * as K from "@dashkite/katana/async"
import * as R from "./resources"
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

getAuthority = ->
  mode = window.env?.mode ? "development"
  if mode == "production"
    "breeze-api.dashkite.com"
  else
    "breeze-#{mode}-api.dashkite.com"

isAuthenticated = ->
  (await Profile.current)? &&
    (await Profile.getAdjunct (await getAuthority()))?

initialize = Fn.flow [
  K.read "handle"
  K.peek (handle, description) ->
    Obj.assign handle.data, {
      description...
      token: getParameters().token
      authority: ( _authority = getAuthority() ) 
      authorities: 
        breeze: _authority
        application: description.domain
      # we store these as objects because they're wrapped as proxies
      # once we assign them to the observed data property
      profiles:
        current: (_current = await Profile.current)?.toObject()
        application: undefined
        breeze: if _current?
          (await Profile.getAdjunct _authority)?.toObject()
    }
]

reset = Fn.flow [
  K.read "handle"
  K.push getAuthority
  K.push (authority, handle, description) ->
    await Profile.getAdjunct authority
  K.pop (profile) -> profile.delete()
  K.push -> Profile.current
  K.pop (profile) -> profile.delete()
  K.peek (authority, handle, description) ->
    Obj.assign handle.data, {
      description...
      token: undefined
      authority: authority
      authorities: 
        breeze: authority
        application: description.domain
      profiles:
        current: undefined
        application: undefined
        breeze: undefined
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

update = (_status) ->
  Fn.tee Fn.flow [
    K.push (data) -> Obj.merge _status, data
    C.render status
  ]

actions =

  "get oauth token": Fn.flow [
    C.render providers
  ]

  "get breeze profile": Fn.flow [
    update message: "Get Breeze profile", stage: 1
    K.poke R.Authentication.post
    K.push -> Profile.current
    K.read "data"
    K.peek (data, profile) -> data.profiles.breeze = profile.toObject()
  ]

  "create breeze profile": Fn.flow [
    update message: "Create Breeze profile", stage: 1
    K.push (data) -> Profile.create data.authorities.breeze, {}
    # we need to set this in case there's no current profile
    K.peek (profile) -> Profile.current = profile
    K.poke (profile) -> profile.toObject()
    K.push (profile, data) ->
      authority: data.authorities.breeze
      nickname: profile.address
      profile: JSON.stringify profile
    K.pop R.Profiles.post
    run "create identity"
  ]

  "create identity": Fn.flow [
    update message: "Create identity", stage: 2
    K.push (profile, data) ->
      authority: data.authorities.breeze
      nickname: profile.address
      token: data.token
    K.pop R.Identities.post
    K.peek (profile, data) -> data.profiles.breeze = profile
  ]

  "get entries": Fn.flow [
    update message: "Get application profile", stage: 2
    K.push (data) ->
      authority: data.authorities.breeze
      nickname: data.profiles.breeze.address
      tag: data.authorities.application
    K.poke R.Entries.get
    K.peek (entries, data) ->
      data.entries = entries
  ]

  "create default profile": Fn.flow [
    update message: "Create default application profile", stage: 2
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
    update message: "Store application profile", stage: 2
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
    run "success"
  ]

  "save entry as local profile": Fn.flow [
    update message: "Store application profile", stage: 2
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
    K.push (entry) -> Profile.createFromJSON entry.content
    K.peek (profile) -> Profile.current = profile
    run "success"
  ]
  
  "reconcile entries": Fn.flow [
    update message: "Reconcile application profile", stage: 2
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
    update message: "Success", stage: 3
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

handler "get breeze profile", (hasStatus 403), run "create breeze profile"

handler "get breeze profile", (hasStatus 404),
  K.peek (data) ->
    Obj.assign data,
      message: "Your token expired. Please login with your provider again."
      token: undefined

handler "get entries", (hasStatus 401), reset

handler "create identity", (hasStatus 404), reset

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
  isAuthenticated
  initialize
  transition
  redirect
}