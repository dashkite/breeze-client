import {flow, curry, rtee} from "@pandastrike/garden"
import Registry from "@dashkite/helium"
import * as k from "@dashkite/katana"
import * as c from "@dashkite/carbon"
import * as r from "../../resources"
import html from "./html.pug"
import css from "./css"

class extends c.Handle

  c.mixin @, [
    c.tag "breeze-connect"
    c.diff
    c.initialize [ c.shadow, c.sheet css ]
    c.connect [
      c.activate [
        c.render html
      ]
      c.event "click", [
        c.matches "button", [
          c.target
          k.spush (target) ->
            service: target.name
            redirectURL: (Registry.get "configuration:breeze").redirectURL
          flow [
            k.push r.OAuth.get
            k.peek (url) -> window.location.assign url
      ] ] ]

      c.event "submit", [
        c.intercept
      ]
  ] ]
