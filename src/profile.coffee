import Zinc from "@dashkite/zinc"
import Registry from "@dashkite/helium"

Profile =

  createFromJSON: (json) ->
    profile = await Zinc.fromJSON json
    await profile.store()

    if (appProfile = await Zinc.current)?
      # Application profile exists.
      # Convert it into an adjunct of the Breeze profile.
      appProfile.address = profile.address
      await appProfile.store()
      Zinc.current = appProfile
    else
      # No application profile available.
      # Since Breeze is availble first, set it to current to orient adjunct
      # management until we get our hands on another profile.
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
