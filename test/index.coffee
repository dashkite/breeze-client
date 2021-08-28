import FS from "fs/promises"
import Path from "path"
import * as Amen from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as _ from "@dashkite/joy"
import * as k from "@dashkite/katana"
import * as m from "@dashkite/mimic"
import browse from "@dashkite/genie-presets/browser"

paths =
  html: Path.resolve "./build/browser/test/client/index.html"
  credentials: Path.resolve "./build/node/test/credentials.json"
  screenshots: Path.resolve "./test/screenshots"

navigate = _.flow [
  k.read "page"
  k.peek (page) -> page.waitForNavigation waitUntil: "domcontentloaded"
]

screenshot = do (counter = 0) -> (name) ->
  _.flow [
    k.read "page"
    k.pop (page) ->
      page.screenshot
        path: "test/screenshots/#{counter++}-#{name}.jpg"
        quality: 100
        # fullPage: true
  ]

do browse ({browser, port}) ->

  # TODO maybe this is something Genie can do?
  loop
    try
      await FS.stat paths.html
      break
    catch
      await _.sleep 100
  
  credentials = JSON.parse await FS.readFile paths.credentials, "utf8"

  await FS.rm paths.screenshots, recursive: true, force: true
  await FS.mkdir paths.screenshots

  state = undefined

  text = (description) ->
    r = ""
    for _k1, _v1 of description
      r += "#{_k1}: "
      for _k2, _v2 of _v1
        if _v2
          r += "+#{_k2} "
        else
          r += "-#{_k2} "
    r.trim()

  authenticate = _.flow [
    m.defined "breeze-connect"
    screenshot "loaded"
    # wait a beat for the component to figure out where we are
    # TODO is there a way we can make this more precise?
    m.sleep 1000
    m.select "breeze-connect"
    m.shadow
    # we only support github for now in this graph
    m.select "button[name='github']"
    # sometimes github seems to just pass us along
    k.test _.isDefined, _.flow [
      m.click
      navigate
      screenshot "login"
      m.select "input[type='text']"
      k.test _.isDefined, _.flow [
        m.type credentials.login
        m.select "input[type='password']"
        m.type credentials.password
        m.select "form"
        m.submit
        # redirect notification from provider
        navigate
        screenshot "redirect"
        # back to our test client
        navigate
      ]
    ]
    screenshot "done"
    m.waitFor -> window.__success?
    k.read "page"
    m.evaluate -> window.__success
    m.assert true
  ]

  test = (description) ->
    Amen.test
      description: text description
      wait: false
      ->
        state = await do _.flow [
          -> state
          k.read "page"
          k.peek (page) ->
            page.evaluate ((description) -> window.__describe description),
              description
          m.waitFor -> window.__ready
          k.read "page"
          k.peek (page) ->
            if description.local.token
              page.goto "http://localhost:#{port}/"
            else
              page.goto "http://localhost:#{port}?token=12345"
          authenticate
        ]

  print await Amen.test "Breeze Client", [

    await Amen.test
      description: "Set up baseline known-good state"
      wait: false
      ->
        state = await do m.launch browser, [
          m.page
          m.goto "http://localhost:#{port}/"
          authenticate
        ]

    Amen.test "state tests", await do ->
      # for i in [0..63]
      for i in [0..5]
        # give GitHub a minute
        await _.sleep 100
        await test
          local:
            breeze: (i & 1) != 0
            app: (i & 2) != 0
            token: (i & 4) != 0
          remote:
            profile: (i & 8) != 0
            entry: (i & 16) != 0
            id: (i & 32) != 0
          
  ]

  process.exit if Amen.success then 0 else 1
