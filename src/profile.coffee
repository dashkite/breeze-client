import Zinc from "@dashkite/zinc"
import Registry from "@dashkite/helium"

Profile =

  createFromJSON: (json) ->
    profile = await Zinc.fromJSON json
    await profile.store()
    Zinc.current = profile

  create: ->
    c = Registry.get "configuration:breeze"
    profile = await Zinc.createAdjunct c.authority

  get: ->
    c = Registry.get "configuration:breeze"
    if (profile = await Zinc.getAdjunct c.authority)?
      profile

  exists: ->
    c = Registry.get "configuration:breeze"
    (await Zinc.getAdjunct c.authority)?

  delete: ->
    c = Registry.get "configuration:breeze"
    if (profile = await Zinc.getAdjunct c.authority)?
      profile.delete()

export default Profile
