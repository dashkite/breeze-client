import {once} from "@pandastrike/garden"
import * as q from "@dashkite/quark"

css = q.build q.sheet [

  q.select ":host", [

    # TODO this is copied from hype client
    #      refactor into dashkite library?
    #      or add to quark?

    q.select "form", [

        q.normalize [ "links" ]

        q.form [
          "responsive"
          "header"
          "section"
          "label"
          "input"
          "textarea"
          "footer"
          "button"
        ]

        q.type "large copy"

        q.select "h1", [
          q.type "heading"
        ]
        q.select "h2", [
          q.type "small heading"
        ]

        q.select "label", [
          q.select "& > *", [
            q.margin bottom: q.rem 1
            q.select "&:last-child", [
              q.margin bottom: 0
            ]
          ]
          q.select "& > .hint", [
            q.type "caption"
            q.select "& > p", [
              q.reset [ "block" ]
              q.margin bottom: q.rem 1
            ]
            q.select "> :first-child", [
              q.select "&::before", [
                q.display "inline-block"
                q.bold
                q.set "content", "'Hint:'"
                q.margin right: q.em 1/4
              ]
            ]
          ]
        ]
      ]

    # TODO why do i need this?
    q.width "inherit"

    q.set "align-self", "center"

    q.select "form > header", [
      q.wrap
      q.select "& > section", [
        q.flex
          grow: 1
          shrink: 1
          basis: q.pct 100
      ] ]

    q.select "form > section:first-of-type", [
      q.flex basis: q.hrem 72
      q.select "> nav > ul", [
        q.reset [ "list" ]
        q.rows
        q.wrap
        q.select "> li", [
          q.margin
            right: q.hrem 2
            bottom: q.hrem 2
          q.select "> button", [
            q.width q.hrem 32
            q.padding "1rem 1rem"

            q.select "> img", [
              q.width q.px 32
              q.height q.px 32
              q.margin right: q.hrem 2
            ] ] ] ] ]

    ] ]

export default css
