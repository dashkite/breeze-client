# Error Handling And Composition

The standard answer to error handling in functional program is to use an error monad. This effectively transforms a value into a no-op proxy, so that each function in a graph becomes a no-op. There are three things I dislike about this model:

- Each function still has to run, even though they aren’t going to do anything.
- Exceptions must be caught and converted into an error monads.
- Each function needs to know about error monads, so it’s intrusive.

This is seen as necessary so that there are no side-effects. However, if we don’t particularly care about that, which we don’t—that’s a different topic, but let’s just stipulate that for the sake of argument—these seems like pointless problems. We can instead simply lean into the fact that we have exceptions instead of pretending they don’t exist.

One approach is to define an exception handling combinator that takes the function to run and second function to handle errors. For example, suppose we have a function, called `restore` that makes an HTTP call. We want to throw if the response isn’t a 200 response. And we want to handle each error type separately: after all, a *403 Not Authorized* isn’t the same as a *404 Not Found*.

- We define a generic called `restoreHTTPError` which matches on the response status. Each case has its own handler.
- We define an `HTTPError` type that wraps the response.
- We write an `expect` combinator that throws an `HTTPError` if the response status isn’t 200-299.
- We drop that into HTTP request graph.
- We introduce a variant of `attempt` that takes a function to call if there’s an exception.



