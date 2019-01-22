#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains helpers for parsing tokens, numbers, integers, floats,
## identifiers, etc.
##
## To unpack raw bytes look at the `streams <streams.html>`_ module.
##
##
## .. code-block::
##    import parseutils
##
##    let logs = @["2019-01-10: OK_", "2019-01-11: FAIL_", "2019-01: aaaa"]
##
##    for log in logs:
##      var res: string
##      if parseUntil(log, res, ':') == 10: # YYYY-MM-DD == 10
##        echo res & " - " & captureBetween(log, ' ', '_')
##        # => 2019-01-10 - OK
##
##
## .. code-block::
##    import parseutils
##    from strutils import Digits, parseInt
##
##    let userInput1 = "2019 school start"
##    let userInput2 = "3 years back"
##
##    let startYear = input1[0..skipWhile(input1, Digits)-1] # 2019
##    let yearsBack = input2[0..skipWhile(input2, Digits)-1] # 3
##
##    echo "Examination is in " & $(parseInt(startYear) + parseInt(yearsBack))
##
##
## **See also:**
## * `strutils module<strutils.html>`_ for combined and identical parsing proc's
## * `json module<json.html>`_ for a JSON parser
## * `parsecfg module<parsecfg.html>`_ for a configuration file parser
## * `parsecsv module<parsecsv.html>`_ for a simple CSV (comma separated value) parser
## * `parseopt module<parseopt.html>`_ for a command line parser
## * `parsexml module<parsexml.html>`_ for a XML / HTML parser
## * `other parsers<lib.html#pure-libraries-parsers>`_ for other parsers


{.deadCodeElim: on.}  # dce option deprecated

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

include "system/inclrtl"

const
  Whitespace = {' ', '\t', '\v', '\r', '\l', '\f'}
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  IdentStartChars = {'a'..'z', 'A'..'Z', '_'}
    ## copied from strutils

proc toLower(c: char): char {.inline.} =
  result = if c in {'A'..'Z'}: chr(ord(c)-ord('A')+ord('a')) else: c

proc parseHex*(s: string, number: var int, start = 0; maxLen = 0): int {.
  rtl, extern: "npuParseHex", noSideEffect.}  =
  ## Parses a hexadecimal number and stores its value in ``number``.
  ##
  ## Returns the number of the parsed characters or 0 in case of an error. This
  ## proc is sensitive to the already existing value of ``number`` and will
  ## likely not do what you want unless you make sure ``number`` is zero. You
  ## can use this feature to *chain* calls, though the result int will quickly
  ## overflow.
  ##
  ## If ``maxLen == 0`` the length of the hexadecimal number has no upper bound.
  ## Else no more than ``start + maxLen`` characters are parsed, up to the
  ## length of the string.
  runnableExamples:
    var value = 0
    discard parseHex("0x38", value)
    assert value == 56
    discard parseHex("0x34", value)
    assert value == 56 * 256 + 52
    value = -1
    discard parseHex("0x38", value)
    assert value == -200
  var i = start
  var foundDigit = false
  # get last index based on minimum `start + maxLen` or `s.len`
  let last = min(s.len, if maxLen == 0: s.len else: i+maxLen)
  if i+1 < last and s[i] == '0' and (s[i+1] in {'x', 'X'}): inc(i, 2)
  elif i < last and s[i] == '#': inc(i)
  while i < last:
    case s[i]
    of '_': discard
    of '0'..'9':
      number = number shl 4 or (ord(s[i]) - ord('0'))
      foundDigit = true
    of 'a'..'f':
      number = number shl 4 or (ord(s[i]) - ord('a') + 10)
      foundDigit = true
    of 'A'..'F':
      number = number shl 4 or (ord(s[i]) - ord('A') + 10)
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseOct*(s: string, number: var int, start = 0, maxLen = 0): int  {.
  rtl, extern: "npuParseOct", noSideEffect.} =
  ## Parses an octal number and stores its value in ``number``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  ##
  ## If ``maxLen == 0`` the length of the octal number has no upper bound.
  ## Else no more than ``start + maxLen`` characters are parsed, up to the
  ## length of the string.
  runnableExamples:
    var res: int
    doAssert parseOct("12", res) == 2
    doAssert res == 10
    doAssert parseOct("9", res) == 0
  var i = start
  var foundDigit = false
  # get last index based on minimum `start + maxLen` or `s.len`
  let last = min(s.len, if maxLen == 0: s.len else: i+maxLen)
  if i+1 < last and s[i] == '0' and (s[i+1] in {'o', 'O'}): inc(i, 2)
  while i < last:
    case s[i]
    of '_': discard
    of '0'..'7':
      number = number shl 3 or (ord(s[i]) - ord('0'))
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseBin*(s: string, number: var int, start = 0, maxLen = 0): int {.
  rtl, extern: "npuParseBin", noSideEffect.} =
  ## Parses an binary number and stores its value in ``number``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  ##
  ## If ``maxLen == 0`` the length of the binary number has no upper bound.
  ## Else no more than ``start + maxLen`` characters are parsed, up to the
  ## length of the string.
  runnableExamples:
    var res: int
    doAssert parseBin("010011100110100101101101", res) == 24
    doAssert parseBin("3", res) == 0
  var i = start
  var foundDigit = false
  # get last index based on minimum `start + maxLen` or `s.len`
  let last = min(s.len, if maxLen == 0: s.len else: i+maxLen)
  if i+1 < last and s[i] == '0' and (s[i+1] in {'b', 'B'}): inc(i, 2)
  while i < last:
    case s[i]
    of '_': discard
    of '0'..'1':
      number = number shl 1 or (ord(s[i]) - ord('0'))
      foundDigit = true
    else: break
    inc(i)
  if foundDigit: result = i-start

proc parseIdent*(s: string, ident: var string, start = 0): int =
  ## Parses an identifier and stores it in ``ident``. Returns
  ## the number of the parsed characters or 0 in case of an error.
  runnableExamples:
    var res: string
    doAssert parseIdent("Hello World", res, 0) == 5
    doAssert res == "Hello"
    doAssert parseIdent("Hello World", res, 1) == 4
    doAssert res == "ello"
    doAssert parseIdent("Hello World", res, 6) == 5
    doAssert res == "World"
  var i = start
  if i < s.len and s[i] in IdentStartChars:
    inc(i)
    while i < s.len and s[i] in IdentChars: inc(i)
    ident = substr(s, start, i-1)
    result = i-start

proc parseIdent*(s: string, start = 0): string =
  ## Parses an identifier and returns it or an empty string in
  ## case of an error.
  runnableExamples:
    doAssert parseIdent("Hello World", 0) == "Hello"
    doAssert parseIdent("Hello World", 1) == "ello"
    doAssert parseIdent("Hello World", 5) == ""
    doAssert parseIdent("Hello World", 6) == "World"
  result = ""
  var i = start
  if i < s.len and s[i] in IdentStartChars:
    inc(i)
    while i < s.len and s[i] in IdentChars: inc(i)
    result = substr(s, start, i-1)

proc skipWhitespace*(s: string, start = 0): int {.inline.} =
  ## Skips the whitespace starting at ``s[start]``. Returns the number of
  ## skipped characters.
  runnableExamples:
    doAssert skipWhitespace("Hello World", 0) == 0
    doAssert skipWhitespace(" Hello World", 0) == 1
    doAssert skipWhitespace("Hello World", 5) == 1
    doAssert skipWhitespace("Hello  World", 5) == 2
  while start+result < s.len and s[start+result] in Whitespace: inc(result)

proc skip*(s, token: string, start = 0): int {.inline.} =
  ## Skips the `token` starting at ``s[start]``. Returns the length of `token`
  ## or 0 if there was no `token` at ``s[start]``.
  runnableExamples:
    doAssert skip("2019-01-22", "2019", 0) == 4
    doAssert skip("2019-01-22", "19", 0) == 0
    doAssert skip("2019-01-22", "19", 2) == 2
    doAssert skip("CAPlow", "CAP", 0) == 3
    doAssert skip("CAPlow", "cap", 0) == 0
  while start+result < s.len and result < token.len and
      s[result+start] == token[result]:
    inc(result)
  if result != token.len: result = 0

proc skipIgnoreCase*(s, token: string, start = 0): int =
  ## Same as `skip` but case is ignored for token matching.
  runnableExamples:
    doAssert skipIgnoreCase("CAPlow", "CAP", 0) == 3
    doAssert skipIgnoreCase("CAPlow", "cap", 0) == 3
  while start+result < s.len and result < token.len and
      toLower(s[result+start]) == toLower(token[result]): inc(result)
  if result != token.len: result = 0

proc skipUntil*(s: string, until: set[char], start = 0): int {.inline.} =
  ## Skips all characters until one char from the set `until` is found
  ## or the end is reached.
  ## Returns number of characters skipped.
  runnableExamples:
    doAssert skipUntil("Hello World", {'W', 'e'}, 0) == 1
    doAssert skipUntil("Hello World", {'W'}, 0) == 6
    doAssert skipUntil("Hello World", {'W', 'd'}, 0) == 6
  while start+result < s.len and s[result+start] notin until: inc(result)

proc skipUntil*(s: string, until: char, start = 0): int {.inline.} =
  ## Skips all characters until the char `until` is found
  ## or the end is reached.
  ## Returns number of characters skipped.
  runnableExamples:
    doAssert skipUntil("Hello World", 'o', 0) == 4
    doAssert skipUntil("Hello World", 'o', 4) == 0
    doAssert skipUntil("Hello World", 'W', 0) == 6
    doAssert skipUntil("Hello World", 'w', 0) == 11
  while start+result < s.len and s[result+start] != until: inc(result)

proc skipWhile*(s: string, toSkip: set[char], start = 0): int {.inline.} =
  ## Skips all characters while one char from the set `token` is found.
  ## Returns number of characters skipped.
  runnableExamples:
    doAssert skipWhile("Hello World", {'H', 'e'}) == 2
    doAssert skipWhile("Hello World", {'e'}) == 0
    doAssert skipWhile("Hello World", {'W', 'o', 'r'}, 6) == 3
  while start+result < s.len and s[result+start] in toSkip: inc(result)

proc parseUntil*(s: string, token: var string, until: set[char],
                 start = 0): int {.inline.} =
  ## Parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters notin `until`.
  runnableExamples:
    var myToken: string
    doAssert parseUntil("Hello World", myToken, {'W', 'o', 'r'}) == 4
    doAssert myToken == "Hell"
    doAssert parseUntil("Hello World", myToken, {'W', 'r'}) == 6
    doAssert myToken == "Hello "
    doAssert parseUntil("Hello World", myToken, {'W', 'r'}, 3) == 3
    doAssert myToken == "lo "
  var i = start
  while i < s.len and s[i] notin until: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc parseUntil*(s: string, token: var string, until: char,
                 start = 0): int {.inline.} =
  ## Parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of any character that is not the `until` character.
  runnableExamples:
    var myToken: string
    doAssert parseUntil("Hello World", myToken, 'W') == 6
    doAssert myToken == "Hello "
    doAssert parseUntil("Hello World", myToken, 'o') == 4
    doAssert myToken == "Hell"
    doAssert parseUntil("Hello World", myToken, 'o', 2) == 2
    doAssert myToken == "ll"
  var i = start
  while i < s.len and s[i] != until: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc parseUntil*(s: string, token: var string, until: string,
                 start = 0): int {.inline.} =
  ## Parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of any character that comes before the `until`  token.
  runnableExamples:
    var myToken: string
    doAssert parseUntil("Hello World", myToken, "Wor") == 6
    doAssert myToken == "Hello "
    doAssert parseUntil("Hello World", myToken, "Wor", 2) == 4
    doAssert myToken == "llo "
  if until.len == 0:
    token.setLen(0)
    return 0
  var i = start
  while i < s.len:
    if s[i] == until[0]:
      var u = 1
      while i+u < s.len and u < until.len and s[i+u] == until[u]:
        inc u
      if u >= until.len: break
    inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc parseWhile*(s: string, token: var string, validChars: set[char],
                 start = 0): int {.inline.} =
  ## Parses a token and stores it in ``token``. Returns
  ## the number of the parsed characters or 0 in case of an error. A token
  ## consists of the characters in `validChars`.
  runnableExamples:
    var myToken: string
    doAssert parseWhile("Hello World", myToken, {'W', 'o', 'r'}, 0) == 0
    doAssert myToken.len() == 0
    doAssert parseWhile("Hello World", myToken, {'W', 'o', 'r'}, 6) == 3
    doAssert myToken == "Wor"
  var i = start
  while i < s.len and s[i] in validChars: inc(i)
  result = i-start
  token = substr(s, start, i-1)

proc captureBetween*(s: string, first: char, second = '\0', start = 0): string =
  ## Finds the first occurrence of ``first``, then returns everything from there
  ## up to ``second`` (if ``second`` is '\0', then ``first`` is used).
  runnableExamples:
    doAssert captureBetween("Hello World", 'e') == "llo World"
    doAssert captureBetween("Hello World", 'e', 'r') == "llo Wo"
    doAssert captureBetween("Hello World", 'l', start = 6) == "d"
  var i = skipUntil(s, first, start)+1+start
  result = ""
  discard s.parseUntil(result, if second == '\0': first else: second, i)

proc integerOutOfRangeError() {.noinline.} =
  raise newException(ValueError, "Parsed integer outside of valid range")

# See #6752
when defined(js):
  {.push overflowChecks: off.}

proc rawParseInt(s: string, b: var BiggestInt, start = 0): int =
  var
    sign: BiggestInt = -1
    i = start
  if i < s.len:
    if s[i] == '+': inc(i)
    elif s[i] == '-':
      inc(i)
      sign = 1
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      let c = ord(s[i]) - ord('0')
      if b >= (low(BiggestInt) + c) div 10:
        b = b * 10 - c
      else:
        integerOutOfRangeError()
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    if sign == -1 and b == low(BiggestInt):
      integerOutOfRangeError()
    else:
      b = b * sign
      result = i - start

when defined(js):
  {.pop.} # overflowChecks: off

proc parseBiggestInt*(s: string, number: var BiggestInt, start = 0): int {.
  rtl, extern: "npuParseBiggestInt", noSideEffect, raises: [ValueError].} =
  ## Parses an integer starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there is no integer.
  ## `ValueError` is raised if the parsed integer is out of the valid range.
  runnableExamples:
    var res: BiggestInt
    doAssert parseBiggestInt("9223372036854775807", res, 0) == 19
    doAssert res == 9223372036854775807
  var res: BiggestInt
  # use 'res' for exception safety (don't write to 'number' in case of an
  # overflow exception):
  result = rawParseInt(s, res, start)
  if result != 0:
    number = res

proc parseInt*(s: string, number: var int, start = 0): int {.
  rtl, extern: "npuParseInt", noSideEffect, raises: [ValueError].} =
  ## Parses an integer starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there is no integer.
  ## `ValueError` is raised if the parsed integer is out of the valid range.
  runnableExamples:
    var res: int
    doAssert parseInt("2019", res, 0) == 4
    doAssert res == 2019
    doAssert parseInt("2019", res, 2) == 2
    doAssert res == 19
  var res: BiggestInt
  result = parseBiggestInt(s, res, start)
  when sizeof(int) <= 4:
    if res < low(int) or res > high(int):
      integerOutOfRangeError()
  if result != 0:
    number = int(res)

proc parseSaturatedNatural*(s: string, b: var int, start = 0): int {.
  raises: [].}=
  ## Parses a natural number into ``b``. This cannot raise an overflow
  ## error. ``high(int)`` is returned for an overflow.
  ## The number of processed character is returned.
  ## This is usually what you really want to use instead of `parseInt`:idx:.
  runnableExamples:
    var res = 0
    discard parseSaturatedNatural("848", res)
    doAssert res == 848
  var i = start
  if i < s.len and s[i] == '+': inc(i)
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      let c = ord(s[i]) - ord('0')
      if b <= (high(int) - c) div 10:
        b = b * 10 + c
      else:
        b = high(int)
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    result = i - start

proc rawParseUInt(s: string, b: var BiggestUInt, start = 0): int =
  var
    res = 0.BiggestUInt
    prev = 0.BiggestUInt
    i = start
  if i < s.len - 1 and s[i] == '-' and s[i + 1] in {'0'..'9'}:
    integerOutOfRangeError()
  if i < s.len and s[i] == '+': inc(i) # Allow
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      prev = res
      res = res * 10 + (ord(s[i]) - ord('0')).BiggestUInt
      if prev > res:
        integerOutOfRangeError()
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    b = res
    result = i - start

proc parseBiggestUInt*(s: string, number: var BiggestUInt, start = 0): int {.
  rtl, extern: "npuParseBiggestUInt", noSideEffect, raises: [ValueError].} =
  ## Parses an unsigned integer starting at `start` and stores the value
  ## into `number`.
  ## `ValueError` is raised if the parsed integer is out of the valid range.
  runnableExamples:
    var res: BiggestUInt
    doAssert parseBiggestUInt("12", res, 0) == 2
    doAssert res == 12
    doAssert parseBiggestUInt("1111111111111111111", res, 0) == 19
    doAssert res == 1111111111111111111'u64
  var res: BiggestUInt
  # use 'res' for exception safety (don't write to 'number' in case of an
  # overflow exception):
  result = rawParseUInt(s, res, start)
  if result != 0:
    number = res

proc parseUInt*(s: string, number: var uint, start = 0): int {.
  rtl, extern: "npuParseUInt", noSideEffect, raises: [ValueError].} =
  ## Parses an unsigned integer starting at `start` and stores the value
  ## into `number`.
  ## `ValueError` is raised if the parsed integer is out of the valid range.
  runnableExamples:
    var res: uint
    doAssert parseUInt("3450", res) == 4
    doAssert res == 3450
    doAssert parseUInt("3450", res, 2) == 2
    doAssert res == 50
  var res: BiggestUInt
  result = parseBiggestUInt(s, res, start)
  when sizeof(BiggestUInt) > sizeof(uint) and sizeof(uint) <= 4:
    if res > 0xFFFF_FFFF'u64:
      integerOutOfRangeError()
  if result != 0:
    number = uint(res)

proc parseBiggestFloat*(s: string, number: var BiggestFloat, start = 0): int {.
  magic: "ParseBiggestFloat", importc: "nimParseBiggestFloat", noSideEffect.}
  ## Parses a float starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if a parsing error
  ## occurred.

proc parseFloat*(s: string, number: var float, start = 0): int {.
  rtl, extern: "npuParseFloat", noSideEffect.} =
  ## Parses a float starting at `start` and stores the value into `number`.
  ## Result is the number of processed chars or 0 if there occurred a parsing
  ## error.
  runnableExamples:
    var res: float
    doAssert parseFloat("32", res, 0) == 2
    doAssert res == 32.0
    doAssert parseFloat("32.57", res, 0) == 5
    doAssert res == 32.57
    doAssert parseFloat("32.57", res, 3) == 2
    doAssert res == 57.00
  var bf: BiggestFloat
  result = parseBiggestFloat(s, bf, start)
  if result != 0:
    number = bf

type
  InterpolatedKind* = enum   ## Describes for `interpolatedFragments`
                             ## which part of the interpolated string is
                             ## yielded; for example in "str$$$var${expr}"
    ikStr,                   ## ``str`` part of the interpolated string
    ikDollar,                ## escaped ``$`` part of the interpolated string
    ikVar,                   ## ``var`` part of the interpolated string
    ikExpr                   ## ``expr`` part of the interpolated string

iterator interpolatedFragments*(s: string): tuple[kind: InterpolatedKind,
  value: string] =
  ## Tokenizes the string `s` into substrings for interpolation purposes.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   for k, v in interpolatedFragments("  $this is ${an  example}  $$"):
  ##     echo "(", k, ", \"", v, "\")"
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   (ikString, "  ")
  ##   (ikExpr, "this")
  ##   (ikString, " is ")
  ##   (ikExpr, "an  example")
  ##   (ikString, "  ")
  ##   (ikDollar, "$")
  var i = 0
  var kind: InterpolatedKind
  while true:
    var j = i
    if j < s.len and s[j] == '$':
      if j+1 < s.len and s[j+1] == '{':
        inc j, 2
        var nesting = 0
        block curlies:
          while j < s.len:
            case s[j]
            of '{': inc nesting
            of '}':
              if nesting == 0:
                inc j
                break curlies
              dec nesting
            else: discard
            inc j
          raise newException(ValueError,
            "Expected closing '}': " & substr(s, i, s.high))
        inc i, 2 # skip ${
        kind = ikExpr
      elif j+1 < s.len and s[j+1] in IdentStartChars:
        inc j, 2
        while j < s.len and s[j] in IdentChars: inc(j)
        inc i # skip $
        kind = ikVar
      elif j+1 < s.len and s[j+1] == '$':
        inc j, 2
        inc i # skip $
        kind = ikDollar
      else:
        raise newException(ValueError,
          "Unable to parse a varible name at " & substr(s, i, s.high))
    else:
      while j < s.len and s[j] != '$': inc j
      kind = ikStr
    if j > i:
      # do not copy the trailing } for ikExpr:
      yield (kind, substr(s, i, j-1-ord(kind == ikExpr)))
    else:
      break
    i = j

when isMainModule:
  import sequtils
  let input = "$test{}  $this is ${an{  example}}  "
  let expected = @[(ikVar, "test"), (ikStr, "{}  "), (ikVar, "this"),
                   (ikStr, " is "), (ikExpr, "an{  example}"), (ikStr, "  ")]
  doAssert toSeq(interpolatedFragments(input)) == expected

  var value = 0
  discard parseHex("0x38", value)
  doAssert value == 56
  discard parseHex("0x34", value)
  doAssert value == 56 * 256 + 52
  value = -1
  discard parseHex("0x38", value)
  doAssert value == -200

  value = -1
  doAssert(parseSaturatedNatural("848", value) == 3)
  doAssert value == 848

  value = -1
  discard parseSaturatedNatural("84899999999999999999324234243143142342135435342532453", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("9223372036854775808", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("9223372036854775807", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("18446744073709551616", value)
  doAssert value == high(int)

  value = -1
  discard parseSaturatedNatural("18446744073709551615", value)
  doAssert value == high(int)

  value = -1
  doAssert(parseSaturatedNatural("1_000_000", value) == 9)
  doAssert value == 1_000_000

  var i64Value: int64
  discard parseBiggestInt("9223372036854775807", i64Value)
  doAssert i64Value == 9223372036854775807

{.pop.}
