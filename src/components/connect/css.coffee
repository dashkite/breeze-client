import {once} from "@pandastrike/garden"
import * as q from "@dashkite/quark"
import * as b from "../../quarks"

css = q.build q.sheet [
  q.select ":host", [
    
    # TODO why do i need this?
    q.width "inherit"

    q.set "align-self", "center"

    b.presets [ "simple form" ]

    q.select "form > header", [
      q.wrap
      q.select "& > section", [
        q.flex
          grow: 1
          shrink: 1
          basis: q.pct 100
      ] ]

    q.select "nav > ul", [
      q.reset [ "list" ]
      q.select "button[name = 'google'] > img", [
        q.width q.px 32
        q.height q.px 32
        q.margin right: q.hrem 2
      ]
    ]
  ]

]

export default css
