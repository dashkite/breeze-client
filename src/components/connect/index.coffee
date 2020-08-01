import {flow, curry, rtee} from "@pandastrike/garden"
import * as k from "@dashkite/katana"
import * as c from "@dashkite/carbon"
import html from "./html.pug"
import css from "./css"

import {google} from "authenticators"

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
          k.pop google
        ]
      ]
    ]
  ]
