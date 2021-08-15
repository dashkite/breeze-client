import Zinc from "@dashkite/zinc"
import Registry from "@dashkite/helium"
import * as Fn from "@dashkite/joy/function"
import * as Pr from "@dashkite/joy/predicate"
import * as T from "@dashkite/joy/type"
import * as Obj from "@dashkite/joy/object"

Profile =

  createFromJSON: (json) ->
    profile = await Zinc.fromJSON json
    await profile.store()

    if (appProfile = await Zinc.current)?
      # Application profile exists.
      # Convert it into an adjunct of the Breeze profile.
      appProfile.address = profile.address
      await appProfile.store()
      # TODO do we need to set this?
      Zinc.current = appProfile
    else
      # No application profile available.
      # Since Breeze is availble first, set it to current to orient adjunct
      # management until we get our hands on another profile.
      Zinc.current = profile

  create: Fn.flow [
    Fn.wrap Registry.get "breeze.authority"
    Zinc.createAdjunct
  ]

  get: Fn.flow [
    Fn.wrap Registry.get "breeze.authority"
    Zinc.getAdjunct
  ]

  exists: Fn.flow [
    Fn.wrap Registry.get "breeze.authority"
    Zinc.getAdjunct
    T.isDefined
  ]

  delete: Fn.flow [
    Fn.wrap Registry.get "breeze.authority"
    Zinc.getAdjunct
    Pr.test T.isDefined, Fn.send "delete", []
  ]

export { Profile }
