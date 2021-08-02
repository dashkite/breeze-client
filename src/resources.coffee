import {flow, curry, tee} from "@dashkite/joy/function"
import { getter } from "@dashkite/joy/metaclass"
import Registry from "@dashkite/helium"
import * as m from "@dashkite/mercury"
import * as k from "@dashkite/katana"
import * as s from "@dashkite/mercury-sky"
import * as z from "@dashkite/mercury-zinc"
import p from "./profile"

mask = curry (fields, object) ->
  r = {}
  for field in fields
    r[field] = object[field]
  r

data = (fields) ->
  flow [
    k.read "data"
    k.poke mask fields
  ]

He =
  read: (field) -> -> Registry.get("configuration:breeze")[field]

initialize = flow [
  m.mode "cors"
  k.push He.read "api"
  s.discover
]

fetchAPIKey = flow [
  m.request [
    initialize
    s.resource "public keys"
    m.parameters type: "encryption"
    m.accept "text/plain"
    s.method "get"
    m.cache "breeze"
  ]
  m.text
  k.get
]

loadGrants = tee flow [
  k.push (json) -> json
  k.push fetchAPIKey
  k.push He.read "authority"
  k.mpoke (authority, key, data) -> z.grants authority, key, data
]

Profiles =
  post: flow [
    m.request [
      initialize
      s.resource "profiles"
      s.method "post"
      data [ "nickname", "profile" ]
      m.content
      k.push He.read "authority"
      z.sigil
      m.authorize
    ]
    m.json
    loadGrants
    k.get
  ]

Identities =
  post: flow [
    m.request [
      initialize
      s.resource "identities"
      s.method "post"
      data [ "nickname" ]
      m.parameters
      # TODO do we need to re-read data here?
      data [ "token" ]
      m.content
      k.push He.read "authority"
      z.claim
      m.authorize
    ]
    m.json
    k.get
  ]

Authentication =
  post: flow [
    m.request [
      initialize
      s.resource "authentication"
      s.method "post"
      data [ "token" ]
      m.content
    ]
  ]

  # Upon successful authentication with Breeze and any HX updates after scrutinzing the response, process the response body and store.
  parseProfile: flow [
    m.json
    # restore the breeze profile so that
    # we can accept the grants ...
    tee flow [
      getter "json"
      getter "profile"
      p.createFromJSON
    ]
    loadGrants
    k.get
  ]

Entries =
  get: flow [
    m.request [
      initialize
      s.resource "entries"
      s.method "get"
      data  [ "nickname", "tag" ]
      m.parameters
      k.push He.read "authority"
      z.claim
      m.authorize
    ]
    m.json
    k.get
  ]

  post: flow [
    m.request [
      initialize
      s.resource "entries"
      s.method "post"
      data [ "nickname" ]
      m.parameters
      data [ "content", "displayName" ]
      m.content
      k.push He.read "authority"
      z.claim
      m.authorize
    ]
    m.json
    k.get
  ]

Entry =
  get: flow [
    m.request [
      initialize
      s.resource "entry"
      s.method "get"
      data [ "nickname", "id" ]
      m.parameters
      k.push He.read "authority"
      z.claim
      m.authorize
    ]
    m.json
    k.get
  ]

Tag =
  put: flow [
    m.request [
      initialize
      s.resource "tag"
      s.method "put"
      data [ "nickname", "id", "tag" ]
      m.parameters
      k.push He.read "authority"
      z.claim
      m.authorize
    ]
  ]

# in this case, we aren't making the request,
# we just need to build up the URL based on discovery
# TODO this won't work since currently Mercury doesn't allow
# for a request to be created without being run :/
OAuth =
  get: flow [
    m.request [
      initialize
      s.resource "oauth authentication"
      s.method "get"
      data [ "service", "redirectURL" ]
      m.parameters
    ]
    getter "url"
    getter "href"
  ]

export {Profiles, Identities, Authentication, Entries, Entry, Tag, OAuth}
