import {flow, curry, tee} from "@pandastrike/garden"
import Registry from "@dashkite/helium"
import * as m from "@dashkite/mercury"
import * as k from "@dashkite/katana"
import s from "@dashkite/mercury-sky"
import z from "@dashkite/mercury-zinc"
import p from "./profile"
import {get} from "./helpers"

HeRead = (field) ->
  -> Registry.get("configuration:breeze")[field]

initialize = flow [
  m.use m.Fetch.client mode: "cors"
  m.from [
    HeRead "api"
    s.discover
  ]
]

fetchAPIKey = flow [
  initialize
  s.resource "public keys"
  m.parameters type: "encryption"
  m.accept "text/plain"
  s.method "get"
  m.cache flow [
    s.request
    m.text
    get "text"
  ]
]

loadGrants = k.stack flow [
  k.push (json) -> json
  k.push fetchAPIKey
  k.push HeRead "authority"
  k.mpoke (authority, key, data) -> z.grants authority, key, data
]

Profiles =
  post: flow [
    initialize
    s.resource "profiles"
    s.method "post"
    m.from [
      m.data [ "nickname", "profile" ]
      m.content
    ]
    m.from [
      HeRead "authority"
      z.sigil
      m.authorize
    ]
    s.request
    m.json
    loadGrants
    get "json"
  ]

Identities =
  post: flow [
    initialize
    s.resource "identities"
    s.method "post"
    m.from [
      m.data [ "nickname" ]
      m.parameters
    ]
    m.from [
      m.data [ "token" ]
      m.content
    ]
    m.from [
      HeRead "authority"
      z.claim
      m.authorize
    ]
    s.request
    m.json
    get "json"
  ]

Authentication =
  post: flow [
    initialize
    s.resource "authentication"
    s.method "post"
    m.from [
      m.data [ "token" ]
      m.content
    ]
    m.request
  ]

  # Upon successful authentication with Breeze and any HX updates after scrutinzing the response, process the response body and store.
  parseProfile: flow [
    m.json
    # restore the breeze profile so that
    # we can accept the grants ...
    tee flow [
      get "json"
      get "profile"
      p.createFromJSON
    ]
    loadGrants
    get "json"
  ]

Entries =
  get: flow [
    initialize
    s.resource "entries"
    s.method "get"
    m.from [
      m.data [ "nickname", "tag" ]
      m.parameters
    ]
    m.from [
      HeRead "authority"
      z.claim
      m.authorize
    ]
    m.request
    m.json
    get "json"
  ]

  post: flow [
    initialize
    s.resource "entries"
    s.method "post"
    m.from [
      m.data [ "nickname" ]
      m.parameters
    ]
    m.from [
      m.data [ "content", "displayName" ]
      m.content
    ]
    m.from [
      HeRead "authority"
      z.claim
      m.authorize
    ]
    s.request
    m.json
    get "json"
  ]

Entry =
  get: flow [
    initialize
    s.resource "entry"
    s.method "get"
    m.from [
      m.data [ "nickname", "id" ]
      m.parameters
    ]
    m.from [
      HeRead "authority"
      z.claim
      m.authorize
    ]
    m.request
    m.json
    get "json"
  ]

Tag =
  put: flow [
    initialize
    s.resource "tag"
    s.method "put"
    m.from [
      m.data [ "nickname", "id", "tag" ]
      m.parameters
    ]
    m.from [
      HeRead "authority"
      z.claim
      m.authorize
    ]
    s.request
  ]

# in this case, we aren't making the request,
# we just need to build up the URL based on discovery
OAuth =
  get: flow [
    initialize
    s.resource "oauth authentication"
    s.method "get"
    m.from [
      m.data [ "service", "redirectURL" ]
      m.parameters
    ]
    get "url"
    get "href"
  ]

export {Profiles, Identities, Authentication, Entries, Entry, Tag, OAuth}
