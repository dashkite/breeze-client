import FS from "fs/promises"
import Path from "path"
import { test, success } from "@dashkite/amen"
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

screenshot = do (counter = 0) -> ->
  m.screenshot
    path: "test/screenshots/#{counter++}.jpg"
    quality: 100

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

  print await test "Breeze Client", [

    test
      description: "No existing profile"
      wait: false
      ->
        await do m.launch browser, [
          m.page
          m.goto "http://localhost:#{port}/"
          # m.waitFor -> window.__test?
          # m.evaluate -> window.__test
          # k.get
          m.defined "breeze-connect"
          screenshot()
          m.select "breeze-connect"
          m.shadow
          # we only support google in this graph
          # TODO maybe have conditional flows for each provider?
          m.select "button[name='github']"
          m.click
          navigate
          screenshot()
          m.select "input[type='text']"
          m.type credentials.login
          m.select "input[type='password']"
          m.type credentials.password
          m.select "form"
          m.submit
          # redirect notification from provider
          navigate
          screenshot()
          # back to our test client
          navigate
          screenshot()
          k.read "page"
          k.peek (page) ->
            page.waitForFunction (-> window.__success)
          # m.waitFor -> window.__success
          # m.evaluate -> window.__success
          # m.assert true
        ]

  ]

  process.exit if success then 0 else 1
