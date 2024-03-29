import {flow, pipe, curry, tee} from "@dashkite/joy/function"
import { get } from "@dashkite/joy/object"
import Registry from "@dashkite/helium"
import * as m from "@dashkite/mercury"
import * as K from "@dashkite/katana"
import * as s from "@dashkite/mercury-sky"
import * as z from "@dashkite/mercury-zinc"
import Zinc from "@dashkite/zinc"

getURL = ({authority}) -> "https://#{authority}"

initialize = K.assign [
  m.data [ "authority" ]
  K.push getURL
  s.discover
]

fetchAPIKey = m.start [
  initialize
  pipe [
    s.resource "public keys"
    m.parameters type: "encryption"
    m.accept "text/plain"
    s.method "get"
    # m.cache "breeze"
    m.request
  ]
  m.text
  K.get
]

loadGrants = tee flow [
  K.read "json"
  m.data [ "authority" ]
  K.push fetchAPIKey
  K.mpoke (key, { authority }, data) -> z.grants authority, key, data
]

Profiles =

  post: m.start [
    initialize
    pipe [
      s.resource "profiles"
      s.method "post"
      m.data [ "nickname", "profile" ]
      m.content
      # TODO can we avoid this?
      m.parameters {}
    ]
    m.data "authority"
    z.sigil
    m.authorize
    m.request
    m.json
    loadGrants
    K.get
  ]

Profile =

  delete: m.start [
    initialize
    pipe [
      s.resource "profile"
      s.method "delete"
      m.data [ "nickname" ]
      m.parameters
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
  ]

Identities =

  post: m.start [
    initialize
    pipe [
      s.resource "identities"
      s.method "post"
      m.data [ "nickname" ]
      m.parameters
      m.data [ "token" ]
      m.content
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
    m.json
    K.get
  ]

  get: m.start [
    initialize
    pipe [
      s.resource "identities"
      s.method "get"
      m.data [ "nickname" ]
      m.parameters
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
    m.json
    K.get
  ]

Identity = 

  delete: m.start [
    initialize
    pipe [
      s.resource "identity"
      s.method "delete"
      m.data [ "nickname", "id" ]
      m.parameters
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
  ]

Authentication =
  post: m.start [
    initialize
    pipe [
      s.resource "authentication"
      s.method "post"
      m.data [ "token" ]
      K.peek ({token}) -> console.log "token", token
      m.content
      m.parameters {}
    ]
    m.request
    m.json
    K.poke get "profile"
    K.push Zinc.fromJSON
    K.peek Zinc.store
    K.peek (profile) -> Zinc.current = profile
    loadGrants
  ]

Entries =

  get: m.start [
    initialize
    pipe [
      s.resource "entries"
      s.method "get"
      m.data [ "nickname", "tag" ]
      m.parameters
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
    m.json
    K.get
  ]

  post: m.start [
    initialize
    pipe [
      s.resource "entries"
      s.method "post"
      m.data [ "nickname" ]
      m.parameters
      m.data [ "content", "displayName" ]
      m.content
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
    m.json
    K.get
  ]

Entry =

  get: m.start [
    initialize
    pipe [
      s.resource "entry"
      s.method "get"
      m.parameters
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
    m.json
    K.get
  ]

  delete: m.start [
    initialize
    pipe [
      s.resource "entry"
      s.method "delete"
      m.data [ "nickname", "id" ]
      m.parameters
    ]
    m.data "authority"
    z.claim
    m.authorize
    m.request
  ]


Tag =

  put: m.start [
    initialize
    pipe [
      s.resource "tag"
      s.method "put"
      m.parameters
    ]
    m.data "authority"
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
      m.data [ "service", "redirectURL" ]
      m.parameters
    ]
    K.context
    K.get
    get "url"
    get "href"
  ]

export {
  Profiles
  Profile
  Identities
  Identity
  Authentication
  Entries
  Entry
  Tag
  OAuth
}
