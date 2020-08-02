import {flow, curry, rtee} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import * as c from "@dashkite/carbon"
import html from "./html.pug"
import css from "./css"
import cf from "../../configuration"

oauth = ->
  base = cf.oauth.provider.baseURL
  query = new URLSearchParams Object.entries cf.oauth.provider.parameters
  window.location.assign "#{base}?#{query}"

class extends c.Handle

  c.mixin @, [
    c.tag "bora-connect"
    c.diff
    c.initialize [ c.shadow, c.sheet css ]
    c.connect [
      c.activate [
        c.render html
      ]
      c.event "click", [
        c.matches "button", [
          k.pop oauth
        ]
      ]
    ]
  ]
