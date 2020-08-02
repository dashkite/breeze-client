import Zinc from "@dashkite/zinc"
import c from "configuration"

Profile =

  createFromJSON: (json) ->
    profile = await Zinc.fromJSON json
    await profile.store()
    Zinc.current = profile

  create: (nickname) ->
    profile = await Zinc.createAdjunct c.breeze.authority, {nickname}

  get: ->
    if (profile = await Zinc.getAdjunct c.breeze.authority)?
      profile

  exists: -> (await Zinc.getAdjunct c.breeze.authority)?

  delete: ->
    if (profile = await Zinc.getAdjunct c.breeze.authority)?
      profile.delete()

export default Profile
