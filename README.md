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

router.add "/oauth{?parameters}",
  name: "oauth"
  flow [
    # render something ...
    ->
      if await profile.exists()
        do flow [
          profile.toJSON
          register "hype", "Hype Profile"
          browse "view"
        ]
      else
        do flow [
          authenticate "hype"
          profile.createFromJSON
          browse "view"
        ]
  ]
```

## API

### *register tag, description, content ⇢ undefined*

Create a local Breeze profile, if one doesn’t exist, create a Breeze identity based on the browser's query parameters, and add an entry for the given identity based on the given tag, description, and content.

### *authenticate tag ⇢ content*

Obtains a Breeze profile based on the browser’s query parameters and returns a promise for the content for the entry corresponding to the given tag.