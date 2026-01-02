# Copyright (C) 2022-2026 Zack Guard
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import ./textslots/textutils
import std/[
  strutils,
  terminal,
]

type
  Textslots* = object
    curSlotIdx {.requiresInit.}: int
    slots*: seq[string] ## the latest contents of each slot
    f: File
    trimMessages: bool

proc cursorMoveLine(f: File; count: int) =
  try:
    if count < 0:
      f.cursorUp(-count)
    elif count > 0:
      f.cursorDown(count)
    f.setCursorXPos(0)
  except OSError:
    discard

proc cursorToSlot*(mp: var Textslots; slotIdx: int) =
  mp.f.cursorMoveLine(slotIdx - mp.curSlotIdx)
  mp.curSlotIdx = slotIdx

proc writeSlot*(mp: var Textslots; slotIdx: int; message: string; erase = true) =
  let message = block:
    let message =
      if mp.trimMessages:
        message.trim(terminalWidth() - 1)
      else:
        message
    let newlineIdx = message.find(Newlines)
    if newlineIdx != -1:
      message[0 ..< newlineIdx]
    else:
      message

  mp.slots[slotIdx] = message
  mp.cursorToSlot(slotIdx)
  if erase:
    mp.f.eraseLine()
  mp.f.write(message)
  mp.f.flushFile()

proc clearSlots*(mp: var Textslots; slotIdxs: Slice[int]) =
  for i in slotIdxs:
    mp.writeSlot(i, "", erase = true)

proc clearSlots*(mp: var Textslots) =
  mp.clearSlots(0 .. mp.slots.high)

proc init*(_: typedesc[Textslots]; outFile = stdout; trimMessages = true): Textslots =
  Textslots(
    curSlotIdx: 0,
    slots: @[""],
    f: outFile,
    trimMessages: trimMessages,
  )

proc addSlot*(mp: var Textslots) =
  # make new job and slot
  mp.cursorToSlot(mp.slots.high)
  for _ in 1..2:
    # twice because we want to have one empty line under the last slot (why?)
    mp.f.writeLine("")
  mp.curSlotIdx += 2
  mp.slots.add("")

proc log*(mp: var Textslots; message: string) =
  mp.cursorToSlot(0)
  for line in message.splitLines:
    mp.f.eraseLine()
    mp.f.writeLine(line)
  for line in mp.slots:
    mp.f.eraseLine()
    mp.f.writeLine(line)
  mp.curSlotIdx = mp.slots.len
