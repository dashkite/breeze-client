# Breeze Client

Web Component for use with the Breeze authentication API.

## Install

```
npm i @dashkite/breeze-client
```

## Usage

In your application, import Breeze Client:

```coffeescript
import "@dashkite/breeze-client"
```

In your markup for your login page, create an instance of the component:

```pug
breeze-connect(
  data-display-name = "Acme, Inc."
  data-domain = "acme.com"
)
```

If the client has not yet authenticated, this will display a list of buttons for each supported provider.

If the client is already authenticated—meaning there is already a profile stored locally—the component will display a success message and generate a `success` event.

If the client state is undefined, the component will attempt to restore a well-defined state, possibly starting with the list of providers.

**Warning:** The component may lose authentication state attempting to restore a well-defined state locally. Your application should attempt to establish a well-defined state prior to loadiing the component.

You may determine the state of local client using the Zinc library. It's the responsibility of your application to try to define an application profile, if applicable. For example, if your application allows for multiple profiles, you should ensure that you determine which profile to use prior to loading the component.

You may determine whether a device is authenticated using the `isAuthenticated` function exported by Breeze Connect.

```coffeescript
import { isAuthenticated } from "@dashkite/breeze-connect"

do ->

  if (await isAuthenticated())
    console.log "Authenticated!"
  else
    console.log "Not yet authenticated."
```
