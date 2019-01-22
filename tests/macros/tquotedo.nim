discard """
output: '''
123
Hallo Welt
Hallo Welt
1
'''
"""

import macros

macro mac(): untyped =
  quote do:
    proc test(): int =
      (proc(): int = result = 123)()

mac()
echo test()

macro foobar(arg: untyped): untyped =
  result = arg
  result.add quote do:
    `result`

foobar:
  echo "Hallo Welt"

# bug #3744
import macros
macro t(): untyped =
  return quote do:
    proc tp(): int =
      result = 1
t()

echo tp()
