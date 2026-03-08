# Errors

Since 1.1.0, Allure cares about a lot of cases and can throw many errors and warns.
<br>All of these are toggleable with `CONFIG` at the top of Allure's source.

## BadType
> *<ins>sth</ins> passed to <ins>sth</ins> has an unusual type: <ins>sth</ins> (<ins>sth</ins> expected)*

Examples:
> *Content passed to `Allure:Node()(HERE)()` has an unusual type: `nil` (`table` expected)*
> *<br>amount passed to `Allure:Workers(HERE)` has an unusual type: `boolean` (`number` expected)*

You've passed something with an unusual type, specifically something that Allure cannot work with.

Toggleable warns and errors:
- Enqueuing a non-function callback into workers (for example an object with `__call` in it's metatable)
    - > Toggle via `WarnWorkerTypes = false`

- Using a weird metatable for `Node:UseMetatable`
    - > Toggle via `WarnUnusualNodeTypes = false`

- Passing non-singleton dependencies in `Allure:Node(HERE)()()`
    - > Toggle via `WarnUnusualNodeTypes = false`

- And some more

## WeirdCallBack

> *"Unusual type of callback (<ins>sth</ins>) was passed to <ins>sth</ins> (<ins>sth</ins> expected)"*

Most of these errors and warns appear within Workers and can be toggled via `WarnWorkerTypes = false`

## Behavioral Errors

Allure closely tracks whatever you're doing. Anything suspicious or conflicting will not remain noticed and will yield an error.
<br>These errors are called behavioral, they don't have a specific description template, can be toggled via `WarnBehavioralErrors = false` and are basically the debug mode of Allure.

Here's some of them:

- > *Unusual type of the <ins>n-th</ins> dependency singleton passed to `Allure:Node(HERE)()()`: The singleton is not a Node. Use `Allure:Node()` on the singleton.<br>If this is intended, you can suppress this warning via the config.*

- > *Content passed to `Allure:Node()(HERE)()` has a `'Dependencies'` key and/or `'Tags'` key. This will conflict with standard functionality and will be overriden.<br>If this is intended, you can suppress this warning via the config.*

- > *Attempt to use `Node:UseTree` twice. If you want to use 2 NodeTrees as node dependencies, merge them.<br>If this is intended, you can suppress this warning via the config.*

- > *Attempt to yield a worker for <ins>sth</ins> seconds.<br>If this is intended, you can suppress this warning via the config.*

- > *`NodeTree:ForEachParallel()` was used on an empty tree.<br>If this is intended, you can suppress this warning via the config.*
- > *`NodeTree:Sort()` was used on an empty tree.<br>If this is intended, you can suppress this warning via the config.*
- > *`NodeTree:SliceNode()` was used on an empty tree.<br>If this is intended, you can suppress this warning via the config.*
- > *`NodeTree:SlicePredicate()` was used on an empty tree.<br>If this is intended, you can suppress this warning via the config.*
  > <br>...

- > *`NodeTree:NodeFromInstance()` received a non-modulescript instance (<ins>sth</ins>)<br>If this is intended, you can suppress this warning via the config.*

Additionally, some critical errors, like this one, cannot be toggled, in order to preserve the system safe and stable:

- > *`Node:UseDependency()` failed to use node meta and `meta.Dependencies`. This is most likely because meta and/or `Dependencies` have been modified. If not, make sure to create an issue on github.*