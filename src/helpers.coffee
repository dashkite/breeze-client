import {arity, curry} from "@pandastrike/garden"

_not = (predicate) ->
  arity predicate.length, (ax...) ->
    if (r = predicate ax...).then?
      r.then (r) -> !r
    else !r

get = curry (name, object) -> object[name]

merge = (objects...) -> Object.assign {}, objects...

export {_not as not, get, merge}
