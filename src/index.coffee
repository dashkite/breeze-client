import * as C from "@dashkite/carbon"
import * as K from "@dashkite/katana/async"
import * as Fn from "@dashkite/joy/function"
import * as M from "@dashkite/joy/metaclass"

import css from "./css"

import * as _ from "./helpers"
export { isAuthenticated } from "./helpers"

class extends C.Handle

  M.mixin @, [
    C.tag "breeze-connect"
    C.diff
    C.initialize [
      C.shadow
      C.sheets main: css
      C.describe [ _.initialize ]
      C.observe "data", [ _.transition ]
      C.event "click", [ C.within "button", [ _.redirect ] ]
  ]
]

