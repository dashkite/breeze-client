import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import * as $ from "@dashkite/breeze-client"

do ->

  window.__test = await do ->

    test "Profile", [

      test "Register", ->

        assert $.register?

    ]
