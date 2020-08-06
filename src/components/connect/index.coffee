import {flow, curry, rtee} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import * as c from "@dashkite/carbon"
import * as r from "../../resources"
import html from "./html.pug"
import css from "./css"
import cf from "../../configuration"

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
            redirectURL: cf.oauth.redirectURL
          flow [
            k.push r.OAuth.get
            k.log "url"
            k.peek (url) -> window.location.assign url
          ] ] ] ] ]
