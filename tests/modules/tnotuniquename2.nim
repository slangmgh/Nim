discard """
  errormsg: "module names need to be unique per Nimble package"
  file: "tnotuniquename/mnotuniquename.nim"
"""

import mnotuniquename
import tnotuniquename/mnotuniquename
