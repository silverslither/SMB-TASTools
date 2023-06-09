--------------------------- TASTools for SMB1/2J on FCEUX with IUP GUI, NTSC -------------------------------

require("iuplua")

mouse = {}
pmouse = {}

function pollinput()
   pmouse = mouse
   mouse = input.get()
end

setup = false

function presetsetup()
   pmouse = {}
   setup = true
end

function _setupclip()
   presetsetup()
   msg.title = "Subpixel Setup (Preset: Max Subpixel Clip)"
   setupconstants = {mode = {15, 0}, offset = 14, lose = true}
end

function _setupwj()
   presetsetup()
   msg.title = "Subpixel Setup (Preset: Min Subpixel Walljump)"
   setupconstants = {mode = {0, 15}, offset = 12, lose = false}
end

function _setupfpg()
   presetsetup()
   msg.title = "Subpixel Setup (Preset: Max Subpixel Flagpole Glitch)"
   setupconstants = {mode = {15, 0}, offset = 13, lose = true}
end

function _setupbonk()
   presetsetup()
   msg.title = "Subpixel Setup (Preset: Min Subpixel Bonk)"
   setupconstants = {mode = {0, 15}, offset = 8, lose = false}
end

function _setupcollision()
   presetsetup()
   msg.title = "Subpixel Setup (Preset: Min Subpixel Collision)"
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
      gui.box(block, 0, block + 15, 239, "#0000007f", "#0000007f")
   else
      gui.box(block, 0, block + 15, 239, "#0000005f", "#0000005f")

      if (pmouse.leftclick) then
         local xspd = memory.readbytesigned(0x57)

         if (xspd < 17 and xspd > -17) then
            msg.title = "ERR: not enough xspd"
            return
         end

         local xmov = xspd * 256 + memory.readbyte(0x705)

         local mxpos = memory.readbyte(0x3ad) * 16 + bit.rshift(memory.readbyte(0x400), 4)
         local bxpos = xmov > 0 and ((block - scroll - setupconstants.offset) * 16 + setupconstants.mode[1]) or ((block - scroll + setupconstants.offset) * 16 + setupconstants.mode[2])
         local subdiff = math.abs(xspd - ((bxpos - mxpos) % xspd))

         local accel = recalcaccel(xspd)
         local loss = manipsubpx(xmov, accel, subdiff, setupconstants.lose, "SubpxSetup")

         msg.title = "Setup done. Lost " .. loss .. " subpixels."
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
         spdtable = {unpack(spdtable, 1, i - 1)}
         local f = subsum(spdtable, subdiff - loss)

         if (f == nil) then
            f = subsum(spdtable, subdiff - loss + (lose and 1 or -1))
         end

         for j = #f, 1, -1 do
            for k = 1, f[j] do
               controller = taseditor.getinput(frame, 1)
               taseditor.submitinputchange(frame, 1, AND(controller, 63))
               frame = frame + 1
            end

            loss = loss + spdtable[j] * f[j]

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

function subsum(choices, target)
   local temp = {}
   temp[0] = {}
   for i = 0, #choices do
      temp[0][i] = 0
   end

   for tt = 1, target do
      for i, c in pairs(choices) do
         if (c <= tt and temp[tt - c] ~= nil and (temp[tt] == nil or temp[tt][0] > temp[tt - c][0] + 1)) then
            temp[tt] = {unpack(temp[tt - c])}
            temp[tt][0] = temp[tt - c][0] + 1
            temp[tt][i] = temp[tt][i] + 1
         end
      end
   end

   return temp[target]
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
      msg.title = "ERR: spd less than 11"
   elseif (spd >= 0x1800) then
      msg.title = "ERR: spd greater or equal to 24"
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
      msg.title = "Applied ground accel."
   end
end

suboffsetter = nil

function _setoffsetter()
   suboffsetter = memory.readbyte(0x705)
   msg.title = string.format("Subspeed Manipulator offsetter set to 0x%02x", suboffsetter)
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
      msg.title = "ERR: low byte of accel is zero"
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
      msg.title = suboffsetter and string.format("Subspeed is already optimal (with offsetter 0x%02x).", suboffsetter) or "Subspeed is already optimal (without offsetter)."
   else
      local fcount = emu.framecount()
      taseditor.setplayback(fcount - fmanip[2])

      for i = fcount - fmanip[2], fcount - 1 do
         taseditor.submitinputchange(i, 1, AND(taseditor.getinput(i, 1), 63))
      end

      taseditor.applyinputchanges("SubspdManip")
      taseditor.setplayback(fcount)
      msg.title = suboffsetter and string.format("Manipulated to frame %d (0x%02x) with offsetter 0x%02x.", fcount - fmanip[2], fmanip[1], suboffsetter) or string.format("Manipulated to frame %d (0x%02x) without offsetter.", fcount - fmanip[2], fmanip[1])
   end
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
   if (not setup) then
      msg.title = suboffsetter and "Unset subspeed manipulator offsetter." or ""
      rem.title = ""
      suboffsetter = nil
      return
   end

   msg.title = ""
   rem.title = ""
   setup = false
end

blackscreeninc = false
activetimer = 0

function calcremainder()
   local state = memory.readbyte(0xe)

   if (state == 0) then
      if (blackscreeninc and rem.title == nil and memory.readbyte(0x7a0) == 7) then
         rem.title = string.format("R%02d", memory.readbyte(0x77f))
         activetimer = 11
      end
   else
      if (state == 3) then
         blackscreeninc = true
      end

      if (state == 5 and rem.title == nil) then
         for i = 1, 6 do
            if (memory.readbyte(0x795 + i) == 6) then
               rem.title = string.format("R%02d", memory.readbyte(0x77f))
               activetimer = i
               break
            end
         end
      end

      if (rem.title == nil and memory.readbyte(0x7a1) == 6) then
         rem.title = string.format("R%02d", memory.readbyte(0x77f))
         activetimer = 12
      end

      if (state == 7) then
         rem.title = ""
         blackscreeninc = false
      end

      if (state == 8) then
         blackscreeninc = false
      end
   end

   if (activetimer ~= 0 and memory.readbyte(0x795 + activetimer) == 0) then
      rem.title = ""
      activetimer = 0
   end
end

function runlua()
   if (taseditor.engaged()) then
      if (not shown) then
         dlg:show()
         shown = true
         msg.title = "v1.0.1"
         rem.title = ""
      end

      pollinput()
      calcremainder()

      if (setup) then
         setuproutine()
      end

      return
   end

   if (shown) then
      clear()
      dlg:hide()
      shown = false
   end
end

function init()
   set = iup.label {title = "SETUP:", expand = "NO", alignment = "acenter", padding = "4x4"}
   clp = iup.button {title = "CLP", expand = "YES", action = _setupclip}
   wlj = iup.button {title = "WLJ", expand = "YES", action = _setupwj}
   fpg = iup.button {title = "FPG", expand = "YES", action = _setupfpg}
   bnk = iup.button {title = "BNK", expand = "YES", action = _setupbonk}
   col = iup.button {title = "COL", expand = "YES", action = _setupcollision}
   hbox1 = iup.hbox {set, clp, wlj, fpg, bnk, col, margin = "4"}

   sub = iup.label {title = "SUBSPD:", expand = "NO", alignment = "acenter", padding = "4x4"}
   off = iup.button {title = "OFF", expand = "YES", action = _setoffsetter}
   max = iup.button {title = "MAX", expand = "YES", action = _maxsubspd}
   min = iup.button {title = "MIN", expand = "YES", action = _minsubspd}
   hig = iup.button {title = "HIG", expand = "YES", action = _hisubspd}
   low = iup.button {title = "LOW", expand = "YES", action = _losubspd}
   hbox2 = iup.hbox {sub, off, max, min, hig, low, margin = "4"}

   msc = iup.label {title = "MISC:", expand = "NO", alignment = "acenter", padding = "4x4"}
   gfa = iup.button {title = "GFA", expand = "YES", action = groundaccel}
   clr = iup.button {title = "CLR", expand = "YES", action = clear}
   hbox3 = iup.hbox {msc, gfa, clr, margin = "4"}

   msg = iup.label {title = "v1.0.1", expand = "YES", alignment = "aleft", padding = "4"}
   rem = iup.label {title = "Rxxx", expand = "NO", alignment = "aright", padding = "4"}
   tbox = iup.hbox {msg, rem, margin = "4"}

   vbox = iup.vbox {tbox, hbox1, hbox2, hbox3, gap = "4", margin = "0x4"}
   dlg = iup.dialog {vbox, title = "SMB1 TASTools by slither", size = "274x72", resize = "NO", border = "NO", bringfront = "YES", menubox = "NO"}

   shown = false
end

function destroy()
   dlg:destroy()
end

init()

gui.register(runlua)
emu.registerexit(destroy)

while (true) do
   emu.frameadvance()
end