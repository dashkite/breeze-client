import Zinc from "@dashkite/zinc"
import Registry from "@dashkite/helium"

# Helper to manage access to the Helium registry used by components.
read = ->
  Registry.get "profiles:breeze:current"

write = (profile) ->
  Registry.set "profiles:breeze:current": profile

Profile =

  createFromJSON: (json) ->
    profile = await Zinc.fromJSON json
    await profile.store()
    Zinc.current = profile
    write profile
    profile

  create: ->
    c = Registry.get "configuration:breeze"
    profile = await Zinc.createAdjunct c.authority
    write profile
    profile

  get: ->
    c = Registry.get "configuration:breeze"
    if (profile = read())?
      profile
    else if (profile = await Zinc.getAdjunct c.authority)?
      write profile
      profile

  exists: -> (await Profile.get())?

  delete: ->
    c = Registry.get "configuration:breeze"
    if (profile = await Zinc.getAdjunct c.authority)?
      profile.delete()
      write undefined

export default Profile
