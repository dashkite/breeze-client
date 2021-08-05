import {flow, pipe, curry, tee} from "@dashkite/joy/function"
import { get } from "@dashkite/joy/object"
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

# TODO use version in Mercury once published
data = (fields) ->
  flow [
    k.read "data"
    k.poke mask fields
  ]

# TODO read function for Helium?
# ex: await Registry.read [ "breeze", "api" ]
# ex: await Registry.read "breeze.api"

He =
  read: (field) -> -> (await Registry.get "breeze")[field]

initialize = k.assign [
  k.push He.read "api"
  s.discover
]

fetchAPIKey = m.start [
  initialize
  pipe [
    s.resource "public keys"
    m.parameters type: "encryption"
    m.accept "text/plain"
    s.method "get"
    m.cache "breeze"
    m.request
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

  post: m.start [
    initialize
    pipe [
      s.resource "profiles"
      s.method "post"
      m.content
      # TODO can we avoid this?
      m.parameters {}
    ]
    k.push He.read "authority"
    z.sigil
    m.authorize
    m.request
    m.json
    loadGrants
    k.get
  ]

Identities =

  post: m.start [
    initialize
    pipe [
      s.resource "identities"
      s.method "post"
      m.parameters
      m.content
    ]
    k.push He.read "authority"
    z.claim
    m.authorize
    m.request
    m.json
    k.get
  ]

Authentication =
  post: m.start [
    initialize
    pipe [
      s.resource "authentication"
      s.method "post"
      m.content
    ]
    m.request
  ]

  # Upon successful authentication with Breeze and any HX updates after
  # scrutinzing the response, process the response body and store.
  parseProfile: flow [
    m.json
    # restore the breeze profile so that
    # we can accept the grants ...
    tee flow [
      k.get
      get "profile"
      p.createFromJSON
    ]
    loadGrants
    k.get
  ]

Entries =

  get: m.start [
    initialize
    pipe [
      s.resource "entries"
      s.method "get"
      m.parameters
    ]
    k.push He.read "authority"
    z.claim
    m.authorize
    m.request
    m.json
    k.get
  ]

  post: m.start [
    initialize
    pipe [
      s.resource "entries"
      s.method "post"
      data [ "nickname" ]
      m.parameters
      data [ "content", "displayName" ]
      m.content
    ]
    k.push He.read "authority"
    z.claim
    m.authorize
    m.request
    m.json
    k.get
  ]

Entry =

  get: m.start [
    initialize
    pipe [
      s.resource "entry"
      s.method "get"
      m.parameters
    ]
    k.push He.read "authority"
    z.claim
    m.authorize
    m.request
    m.json
    k.get
  ]

Tag =

  put: m.start [
    initialize
    pipe [
      s.resource "tag"
      s.method "put"
      m.parameters
    ]
    k.push He.read "authority"
    z.claim
    m.authorize
    m.request
  ]

# In this case, we aren't making the request, we just need to build up the URL
# based on discovery

OAuth =

  get: m.start [
    initialize
    pipe [
      s.resource "oauth authentication"
      s.method "get"
      m.parameters
    ]
    k.context
    k.get
    get "url"
    get "href"
  ]

export {Profiles, Identities, Authentication, Entries, Entry, Tag, OAuth}
