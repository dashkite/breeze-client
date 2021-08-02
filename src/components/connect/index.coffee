import {flow, curry, rtee} from "@dashkite/joy/function"
import * as M from "@dashkite/joy/metaclass"
import Registry from "@dashkite/helium"
import * as k from "@dashkite/katana/sync"
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
          k.push (target) ->
            breeze = await Registry.get "breeze"
            service: target.name
            redirectURL: breeze.redirectURL
          flow [
            c.render waiting
            k.push r.OAuth.get
            k.peek (url) -> window.location.assign url
      ] ] ]

      c.event "submit", [
        c.intercept
      ]
  ] ]
