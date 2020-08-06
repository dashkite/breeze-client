# Breeze Client

Web Component and OAuth handler for use with the Breeze authentication API.

## Install

```
npm i @dashkite/breeze-client
```

## Usage

The Breeze Client includes:

- A Web Component for connecting an identity via the Breeze API
- Two functions, `register` and `authenticate`, which handle OAuth redirects

To use the component, simply import `breeze-client` and render the component using the `breeze-connect` tag.

To handle the OAuth redirect, add an appropriate route and call either `register` or `authenticate`, depending on the circumstances. These are combinator functions, intended to be composed with other functions.

### Example

```coffeescript
# somewhere in your imports
import {register, authenticate} from "@dashkite/breeze-client"

token = ({bindings}) -> bindings.token

router.add "/oauth{?token}",
  name: "oauth"
  flow [
    n.view "main", -> "<p>Connecting &hellip;</p>"
    n.show
    test profile.exists,
      k.stack flow [
        k.push token
        k.push profile.toJSON
        k.mpoke (content, token) -> { content, token }
        k.peek flow [
          register "hype", "Hype Profile"
          profile.get
          browse "view"
        ] ]
      flow [
        token
        authenticate "hype"
        profile.createFromJSON
        browse "view"
      ] ]
```

## API

### *register tag, description, content ⇢ undefined*

Create a local Breeze profile, if one doesn’t exist, create a Breeze identity based on the browser's query parameters, and add an entry for the given identity based on the given tag, description, and content.

### *authenticate tag ⇢ content*

Obtains a Breeze profile based on the browser’s query parameters and returns a promise for the content for the entry corresponding to the given tag.
