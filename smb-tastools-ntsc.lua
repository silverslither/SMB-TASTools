--------------------------- TASTools for SMB1/2J on FCEUX, NTSC -------------------------------

charindex = {
   a = "010101111101101",
   b = "110101110101110",
   c = "011100100100011",
   d = "110101101101110",
   e = "111100111100111",
   f = "111100111100100",
   g = "011100101101011",
   h = "101101111101101",
   i = "111010010010111",
   j = "011001001101011",
   k = "101101110101101",
   l = "100100100100111",
   m = "101111101101101",
   n = "110101101101101",
   o = "010101101101010",
   p = "110101111100100",
   q = "010101101110011",
   r = "110101110101101",
   s = "011100010001110",
   t = "111010010010010",
   u = "101101101101111",
   v = "101101101101010",
   w = "101101101111101",
   x = "101101010101101",
   y = "101101010010010",
   z = "111001010100111",
   ["0"] = "111101101101111",
   ["1"] = "010110010010111",
   ["2"] = "110001010100111",
   ["3"] = "110001110001110",
   ["4"] = "101101111001001",
   ["5"] = "111100110001110",
   ["6"] = "111100111101111",
   ["7"] = "111001010010010",
   ["8"] = "111101111101111",
   ["9"] = "111101111001111",
   [" "] = "000000000000000",
   ["."] = "000000000000010",
   ["-"] = "000000111000000",
   [":"] = "000010000000010",
   ["+"] = "000010111010000",
   ["("] = "001010010010001",
   [")"] = "100010010010100"
}

tools = {clear = {nick = "clr", xpos = 243}, presetsetup = {nick = "set", xpos = 2}, groundaccel = {nick = "gfa", xpos = 17}, subspdsearch = {nick = "sub", xpos = 32}}
setuptools = {clear = {nick = "clr", xpos = 243}, _setupclip = {nick = "clp", xpos = 2}, _setupwj = {nick = "wlj", xpos = 17}, _setupfpg = {nick = "fpg", xpos = 32}, _setupbonk = {nick = "bnk", xpos = 47}, _setupcollision = {nick = "col", xpos = 62}}
subspdtools = {clear = {nick = "clr", xpos = 243}, _setoffsetter = {nick = "off", xpos = 2}, _maxsubspd = {nick = "max", xpos = 17}, _minsubspd = {nick = "min", xpos = 32}, _hisubspd = {nick = "hig", xpos = 47}, _losubspd = {nick = "low", xpos = 62}}
defaulttools = tools

colour = "white"
msg = "smb1 tastools by slither v1.0.0"

mouse = {}
pmouse = {}

function pollinput()
   pmouse = mouse
   mouse = input.get()

   if (mouse.ymouse < 231) then
      return
   end

   if (mouse.leftclick) then
      for i, v in pairs(tools) do
         if (mouse.xmouse >= v.xpos - 2 and mouse.xmouse <= v.xpos + 12) then
            gui.box(v.xpos - 2, 231, v.xpos + 12, 239, "grey", "grey")
         end
      end

      return
   end

   if (pmouse.leftclick) then
      for i, v in pairs(tools) do
         if (mouse.xmouse >= v.xpos - 2 and mouse.xmouse <= v.xpos + 12) then
            _G[i]()
         end
      end
   end
end

setup = false

function presetsetup()
   _setupclip()
   tools = setuptools

   pmouse = {}
   setup = true
end

function _setupclip()
   msg = "subpixel setup - select preset: max subpixel clip"
   setupconstants = {mode = {15, 0}, offset = 14, lose = true}
end

function _setupwj()
   msg = "subpixel setup - select preset: min subpixel walljump"
   setupconstants = {mode = {0, 15}, offset = 12, lose = false}
end

function _setupfpg()
   msg = "subpixel setup - select preset: max subpixel flagpole glitch"
   setupconstants = {mode = {15, 0}, offset = 13, lose = true}
end

function _setupbonk()
   msg = "subpixel setup - select preset: min subpixel bonk"
   setupconstants = {mode = {0, 15}, offset = 8, lose = false}
end

function _setupcollision()
   msg = "subpixel setup - select preset: min subpixel collision"
   setupconstants = {mode = {0, 15}, offset = 13, lose = false}
end

function setuproutine()
   local scroll = memory.readbyte(0x775)
   local offset = memory.readbyte(0x71c) - scroll
   local block = bit.rshift(mouse.xmouse + offset, 4) * 16 - offset

   if (mouse.ymouse >= 224) then
      return
   end

   if (mouse.leftclick) then
      gui.box(block, 0, block + 15, 223, "#0000007f", "#0000007f")
   else
      gui.box(block, 0, block + 15, 223, "#0000005f", "#0000005f")

      if (pmouse.leftclick) then
         local xspd = memory.readbytesigned(0x57)

         if (xspd < 17 and xspd > -17) then
            msg = "err: not enough xspd"
            return
         end

         local xmov = xspd * 256 + memory.readbyte(0x705)

         local mxpos = memory.readbyte(0x3ad) * 16 + bit.rshift(memory.readbyte(0x400), 4)
         local bxpos = xmov > 0 and ((block - scroll - setupconstants.offset) * 16 + setupconstants.mode[1]) or ((block - scroll + setupconstants.offset) * 16 + setupconstants.mode[2])
         local subdiff = math.abs(xspd - ((bxpos - mxpos) % xspd))

         local accel = recalcaccel(xspd)
         local loss = manipsubpx(xmov, accel, subdiff, setupconstants.lose, "SubpxSetup")

         msg = "setup done. lost " .. loss .. " subpixels"
         tools = defaulttools
         setup = false
      end
   end
end

function manipsubpx(xmov, accel, subdiff, lose, taseditorname)
   local xspd = bit.rshift(xmov, 8)
   local dir = xmov > 0
   local loss = 0
   local spdtable = {}
   local frame = emu.framecount()

   if (dir) then
      while (xmov > 0) do
         table.insert(spdtable, xspd - bit.rshift(xmov, 8))
         xmov = xmov - accel
      end
   else
      while (xmov < 0) do
         table.insert(spdtable, bit.rshift(xmov, 8) - xspd)
         xmov = xmov + accel
      end
   end

   for i = 2, #spdtable do
      local controller = taseditor.getinput(frame, 1)

      if (loss + spdtable[i] + spdtable[i - 1] > subdiff) then
         local f = subsum(spdtable, subdiff - loss, i - 1, {})

         if (f == nil) then
            f = subsum(spdtable, subdiff - loss + (lose and 1 or -1), i - 1, {})
         end

         for j = 1, #f do
            for k = 1, f[j] do
               controller = taseditor.getinput(frame, 1)
               taseditor.submitinputchange(frame, 1, AND(controller, 63))
               frame = frame + 1
            end

            loss = loss + spdtable[i - j] * f[j]

            controller = taseditor.getinput(frame, 1)
            taseditor.submitinputchange(frame, 1, dir and AND(OR(controller, 128), 191) or AND(OR(controller, 64), 127))
            frame = frame + 1
         end

         for j = 1, i - #f - 2 do
            controller = taseditor.getinput(frame, 1)
            taseditor.submitinputchange(frame, 1, dir and AND(OR(controller, 128), 191) or AND(OR(controller, 64), 127))
            frame = frame + 1
         end

         break
      end

      loss = loss + spdtable[i] + spdtable[i - 1]
      taseditor.submitinputchange(frame, 1, dir and AND(OR(controller, 64), 127) or AND(OR(controller, 128), 191))
      frame = frame + 1
   end

   taseditor.applyinputchanges(taseditorname)
   return subdiff .. ((loss - subdiff == 0) and "" or " (" .. (lose and "+" or "") .. (loss - subdiff) .. (lose and " more)" or " less)"))
end

function subsum(choices, target, index, steps)
   if (target == 0) then
      return steps
   end

   if (index < 1 or choices[index] == 0) then
      return nil
   end

   for i = target % choices[index], target, choices[index] do
      local nsteps = {unpack(steps)}
      table.insert(nsteps, (target - i) / choices[index])

      local ret = subsum(choices, i, index - 1, nsteps)

      if (ret ~= nil) then
         return ret
      end
   end

   return nil
end

groundaccelconstants = {
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
   {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
}

function groundaccel()
   local spd = memory.readbytesigned(0x57) * 256 + memory.readbyte(0x705)

   if (spd < 0xb00) then
      msg = "err: spd less than 11"
   elseif (spd >= 0x1800) then
      msg = "err: spd greater or equal to 24"
   else
      local prev = (AND(memory.readbyte(0x33), 2) == 2) and 2 or 1
      local frame = emu.framecount()

      if (prev == 2 and memory.readbyte(0x701) * 256 + memory.readbyte(0x702) == 0x1a0) then
         while (spd < 0x1760) do
            spd = spd + 0x1a0
            taseditor.submitinputchange(frame, 1, OR(taseditor.getinput(frame, 1), 192))
            frame = frame + 1
         end

         if (spd < 0x17f8) then
            taseditor.submitinputchange(frame, 1, AND(OR(taseditor.getinput(frame, 1), 128), 191))
            frame = frame + 1
         end
      else
         while (spd < 0x1800) do
            local controller = taseditor.getinput(frame, 1)

            if (prev == 1 or groundaccelconstants[bit.rshift(spd, 8) - 10][bit.rshift(spd % 256, 2) + 1] == 1) then
               spd = spd + ((prev == 2) and 0x130 or 0x98)
               prev = 2
               controller = OR(controller, 192)
            else
               spd = spd + ((prev == 2) and 0x1c8 or 0xe4)
               prev = 1
               controller = AND(OR(controller, 128), 191)
            end

            taseditor.submitinputchange(frame, 1, controller)
            frame = frame + 1
         end
      end

      taseditor.submitinputchange(frame, 1, AND(OR(taseditor.getinput(frame, 1), 128), 191))
      taseditor.applyinputchanges("GroundAccel")
      msg = "applied ground accel"
   end
end

function subspdsearch()
   msg = suboffsetter and string.format("subspeed manipulator - offsetter set to 0x%02x", suboffsetter) or "subspeed manipulator - offsetter not set"
   tools = subspdtools
end

suboffsetter = nil

function _setoffsetter()
   suboffsetter = memory.readbyte(0x705)
   msg = string.format("subspeed manipulator - offsetter set to 0x%02x", suboffsetter)
end

function _maxsubspd()
   manipsubspd(0)
end

function _minsubspd()
   manipsubspd(1)
end

function _hisubspd()
   manipsubspd(2)
end

function _losubspd()
   manipsubspd(3)
end

function manipsubspd(mmode)
   local accel = memory.readbyte(0x702)
   if (accel == 0) then
      msg = "err: low byte of accel is zero"
      tools = defaulttools
      return
   end

   local tempaccel = accel
   local iter = 64
   while (tempaccel % 2 == 0) do
      iter = iter + 1
      tempaccel = tempaccel / 2
   end

   local subspd = memory.readbyte(0x705)
   local offset = suboffsetter and (suboffsetter - subspd) % 256 or 0
   local sign = memory.readbytesigned(0x57) >= 0 and 1 or -1

   local osubspd = (subspd + offset) % 256
   local fmanip

   if (mmode == 0) then
      local max = {osubspd, 0}

      for i = 1, iter - 1 do
         subspd = (subspd - sign * accel) % 256
         osubspd = (subspd + offset) % 256

         if (max[1] < osubspd) then
            max[1] = osubspd
            max[2] = i
         end
      end

      fmanip = max
   elseif (mmode == 1) then
      local min = {osubspd, 0}

      for i = 1, iter - 1 do
         subspd = (subspd - sign * accel) % 256
         osubspd = (subspd + offset) % 256

         if (min[1] > osubspd) then
            min[1] = osubspd
            min[2] = i
         end
      end

      fmanip = min
   elseif (mmode == 2) then
      if (osubspd < 0xf0) then
         local hi = {nil, 0}
         local max = {osubspd, 0}

         for i = 1, iter - 1 do
            subspd = (subspd - sign * accel) % 256
            osubspd = (subspd + offset) % 256

            if (max[1] < osubspd) then
               max[1] = osubspd
               max[2] = i
            end

            if (not hi[1] and osubspd >= 0xf0) then
               hi[1] = osubspd
               hi[2] = i
               break
            end
         end

         fmanip = hi[1] and hi or max
      else
         fmanip = {osubspd, 0}
      end
   elseif (mmode == 3) then
      if (osubspd >= 0x10) then
         local lo = {nil, 0}
         local min = {osubspd, 0}

         for i = 1, iter - 1 do
            subspd = (subspd - sign * accel) % 256
            osubspd = (subspd + offset) % 256

            if (min[1] > osubspd) then
               min[1] = osubspd
               min[2] = i
            end

            if (not lo[1] and osubspd < 0x10) then
               lo[1] = osubspd
               lo[2] = i
               break
            end
         end

         fmanip = lo[1] and lo or min
      else
         fmanip = {osubspd, 0}
      end
   end

   if (fmanip[2] == 0) then
      msg = "subspeed is already optimal"
   else
      local fcount = emu.framecount()
      taseditor.setplayback(fcount - fmanip[2])

      for i = fcount - fmanip[2], fcount - 1 do
         taseditor.submitinputchange(i, 1, AND(taseditor.getinput(i, 1), 63))
      end

      taseditor.applyinputchanges("SubspdManip")
      taseditor.setplayback(fcount)
      msg = string.format("manipulated to frame %d (0x%02x)", fcount - fmanip[2], fmanip[1])
   end

   tools = defaulttools
end

acceltable = {0xe4, 0x98, 0xd0}

function recalcaccel(xspd)
   local leftright = taseditor.getinput(emu.framecount(), 1)
   leftright = bit.rshift(AND(leftright, 64), 5) + bit.rshift(leftright, 7)

   local temp = 1
   local movingdir = memory.readbyte(0x45)

   if (recalcairborne()) then
      if (xspd < 25 and xspd > -25) then
         temp = temp + 1

         if (memory.readbyte(0x703)) then
            temp = temp + 1
         end
      end
   else
      if (memory.readbyte(0x74e) == 0) then
         temp = temp + 1
      elseif (leftright ~= movingdir) then
         temp = temp + 1

         if (memory.readbyte(0x703)) then
            temp = temp + 1
         end
      end
   end

   local accel = acceltable[temp]

   if (memory.readbyte(0x33) ~= movingdir) then
      accel = accel * 2
   end

   return accel
end

function recalcairborne()
   return memory.readbyte(0x1d) ~= 0 or (taseditor.getinput(emu.framecount(), 1) % 2 == 1 and taseditor.getinput(emu.framecount() - 1, 1) % 2 == 0 and memory.readbyte(0x70e) == 0)
end

function clear()
   if (tools == subspdtools and suboffsetter) then
      suboffsetter = nil
      msg = "subspeed manipulator - offsetter not set"
      return
   end

   tools = defaulttools
   msg = ""
   remainder = ""
   setup = false
end

function drawtools()
   drawtext(2, 226, msg)

   for i, v in pairs(tools) do
      drawtext(v.xpos, 233, v.nick)
   end

   if (remainder ~= "") then
      drawtext(228, 233, remainder)
   end
end

blackscreeninc = false
remainder = ""
activetimer = 0

function calcremainder()
   local state = memory.readbyte(0xe)

   if (state == 0) then
      if (blackscreeninc and remainder == "" and memory.readbyte(0x7a0) == 7) then
         remainder = string.format("r%02d", memory.readbyte(0x77f))
         activetimer = 11
      end
   else
      if (state == 3) then
         blackscreeninc = true
      end

      if (state == 5 and remainder == "") then
         for i = 1, 6 do
            if (memory.readbyte(0x795 + i) == 6) then
               remainder = string.format("r%02d", memory.readbyte(0x77f))
               activetimer = i
               break
            end
         end
      end

      if (remainder == "" and memory.readbyte(0x7a1) == 6) then
         remainder = string.format("r%02d", memory.readbyte(0x77f))
         activetimer = 12
      end

      if (state == 7) then
         remainder = ""
         blackscreeninc = false
      end

      if (state == 8) then
         blackscreeninc = false
      end
   end

   if (activetimer ~= 0 and memory.readbyte(0x795 + activetimer) == 0) then
      remainder = ""
      activetimer = 0
   end
end

function drawtext(x, y, str)
   local l = #str
   for i = 1, l do
      drawletter(x + (i - 1) * 4, y, charindex[str:sub(i, i)])
   end
end

function drawletter(x, y, letterdata)
   for i = 0, 2 do
      for j = 0, 4 do
         local stringoffset = j * 3 + i + 1
         if (letterdata:sub(stringoffset, stringoffset) == "1") then
            gui.pixel(x + i, y + j, colour)
         end
      end
   end
end

function drawlua()
   if (taseditor.engaged()) then
      gui.box(0, 224, 255, 239, "black", "black")

      pollinput()
      calcremainder()
      drawtools()

      if (setup) then
         setuproutine()
      end
   end
end

gui.register(drawlua)

while (true) do
   emu.frameadvance()
end