import {arity, curry} from "@pandastrike/garden"

get = curry (name, object) -> object[name]

_not = (predicate) ->
  arity predicate.length, (ax...) ->
    if (r = predicate ax...).then?
      r.then (r) -> !r
    else !r

export {_not as not, get}
