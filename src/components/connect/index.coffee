import {flow, curry, rtee} from "@dashkite/joy/function"
import * as M from "@dashkite/joy/metaclass"
import Registry from "@dashkite/helium"
import * as Ks from "@dashkite/katana/sync"
import * as K from "@dashkite/katana/async"
import * as c from "@dashkite/carbon"
import * as r from "../../resources"
import html from "./html"
import waiting from "./waiting"
import css from "./css"

class extends c.Handle

  M.mixin @, [
    c.tag "breeze-connect"
    c.diff
    c.initialize [
      c.shadow
      c.sheets main: css
      c.activate [
        c.render html
      ]
      c.event "click", [
        c.within "button", [
          Ks.push (target) ->
            breeze = await Registry.get "breeze"
            service: target.name
            redirectURL: breeze.redirectURL
          flow [
            c.render waiting
            K.push r.OAuth.get
            K.peek (url) -> 
              console.log {url}
              window.location.assign url
      ] ] ]

      c.event "submit", [
        c.intercept
      ]
  ] ]
