# Breeze Client

Web Component and OAuth handler for use with the Breeze authentication API.

## Install

```
npm i @dashkite/breeze-client
```

## Usage

The Breeze Client includes:

- A Web Component for connecting an identity via the Breeze API
- A high-level combinator interface for handling OAuth cases.

To use the component, simply import `@dashkite/breeze-client` and render the component using the `breeze-connect` tag.

To handle the OAuth redirect, add an appropriate route and call combinators to access Breeze API resources, depending on the circumstances.

[neon-breeze](https://github.com/dashkite/neon-breeze) was designed specifically to make this easy.

### Helium Configuration

The Breeze Client uses `@dashkite/helium` to reference singleton configuration across the application modules.

```yaml
breeze:
  api: URL for the Breeze API or compatible.
  authority: Name of the capability authority.
  redirectURL: Return URL when redirected back from OAuth identity provider.
  entry: Name for the entry tag the application profile is stored under.
  entryDisplayName: Human-friendly name of the entry.
```

### Example: Authentication

```coffeescript
# somewhere in your imports
import * as b from "@dashkite/breeze-client"

# Authenticate is passed a stack with the Breeze identity token on top.

authenticate = flow [
  b.authenticate
  k.branch [
    [
      (expect 404),
      reportFailure "It looks like this login failed or is stale. Login with your identity provider to try again."
    ]
    [
      (expect 403),
      reportFailure "This login with your identity provider was successful, but it looks like you haven't connected it with your profile. Using a device with your existing profile, connect your profile to allow login across devices."
    ]
    [
      (expect 500),
      reportFailure "There's been a problem, and this login cannot continue."
    ]
    [
      (expect 200),
      flow [
        b.load
        HeRead "entry"
        b.fetchEntry
        k.branch [
          [
            isUndefined,
            reportFailure "This login with your identity provider was successful, but it looks like there isn't a profile connected to it. Using a logged in device, connect your profile to allow login across devices."
          ]
          [
            isDefined,
            flow [
              reportPips 2
              b.readEntry
              p.createFromJSON
              successNavigation
            ]
          ]
] ] ] ] ]
```

## API

### *authenticate*

Obtains a Breeze profile based on the browser’s query parameters and returns a promise for the HTTP response for the profile.

### *load*

Instantiates a Breeze profile when given an OK response from *authenticate*

### *register*

Create a local Breeze profile, if one doesn’t exist, create a Breeze identity based on the browser's query parameters.

### *fetchEntry*

Obtains a Breeze entry reference for the given profile and tag. If it returns `undefined`, the entry does not exist that is associated with the given profile.

### *readEntry*

When given a Breeze entry reference, returns the entry proper.

### *addEntry*

Adds a given entry to a Breeze profile's set of entries and tags it with the given tag.
