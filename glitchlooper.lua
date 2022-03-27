-- Glitch Looper
-- originally written for guitarist 
-- Chris Cretella in 2018
-- revisited 2022
-- 
-- \/ INSTRUCTIONS \/
--
-- ENC2 = select loop (0-4)
-- ENC3 = normal/glitch mode
-- KEY2 = hold to record
-- KEY3 = stop loop playback
--
-- KEY1 hold = ALT
-- ALT+KEY2 = start auto mode
-- ALT+KEY3 = stop auto mode

engine.name = 'GlitchLooper'

local audio = require 'audio'
local selected_channels = {1}
local loopPlaying = {false, false, false, false, false}
local recording = {false, false, false, false, false}
local glitched = {false, false, false, false, false}
local which = 0
local alt = false
local automode = false
local density = 0

function init()
  print("glitched looper")
  audio.level_monitor(1)
  audio.monitor_mono()
  
  density_poll = poll.set("density", function(x) density = x end)
  density_poll:start()
  
  timer = metro.init(auto_mode,1,-1)
  
  --params
  params:add_option("auto mode","auto mode",{"off","on"},1)
  params:set_action("auto mode", function(x) if x == 2 then automode_start() elseif x == 1 then automode_stop() end end )
    
  params:add_number("which","buffer",0,4,0,nil,true)
  params:set_action("which",function(x) which = x; redraw() end)
  
  --params:add_option("state","state",{"cleared","recording","playing"},1)
 --params:set_action("state", function(x) 
   -- if x == 1 then clear_buffer(params:get("which")) 
    --elseif x == 2 then record_buffer(params:get("which"))
    --elseif x == 3 then play_buffer(params:get("which"))
    --  end end )
  
    for i=0,4 do
      --params:add_option("record: ".. i, "record: ".. i, "recording")
      end
  end

auto_mode = function()
    print("density ".. density)
    print("running auto mode")
    if recording[which] == false then
    -- start recording
    loopPlaying[which] = false
    redraw()
    recording[which] = true
    engine.recStart(which)
    redraw()
    --wait
    timer.time = (math.random()*density)+0.5
    elseif recording[which] == true then
    -- stop recording and begin playback
    engine.recEnd(which)
    engine.amp(which, 1.0)
    recording[which] = false
    loopPlaying[which] = true
    redraw()
    --choose new channel for next iteration
    which = (math.random(5)-1)
    print(which)
    end
    -- choose normal or glitch
    if math.random() > 0.5 then
      engine.glitch(which)
      engine.densitySet(which, (1/density))
      glitched[which] = true
      redraw()
      else
      engine.normal(which)
      glitched[which] = false
      redraw()
      end
      -- maybe stop playing
      if loopPlaying[which] == true then
      if math.random() > 0.5 then
        engine.amp(which, 0.0)
          loopPlaying[which] = false
          redraw()
          print("loop ended")
          which = (math.random(5)-1)
          print(which)
          end
        end
    -- wait
    timer.time = (math.random()*density)+0.5
  end

local function screen_update_channels()
  screen.move(0,32)
  screen.font_size(24)
  for channel=0,4 do
    if which == channel  then
      screen.level(15)
      elseif loopPlaying[channel] then
        screen.level(6)
    else
      screen.level(1)
    end
    screen.text(channel)
  end
  --record or playback display
  screen.font_size(8)
  screen.move(0,50)
  if loopPlaying[which] then
    screen.level(15)
    screen.text("Playing")
    end
    if recording[which] then
      screen.level(15)
      screen.text("Recording")
    end
  --normal or glitched display
  screen.move(50,50)
    if glitched[which] then
      screen.level(15)
      screen.text("glitched")
      else
        screen.level(15)
        screen.text("normal")
      end
  screen.move(66,8)
  if automode == true then
    screen.level(15)
    screen.font_size(8)
    screen.text("auto mode on")
    else
      screen.level(2)
      screen.font_size(8)
      screen.text("auto mode off")
      end
      if automode == true then
      screen.move(74,20)
      screen.level(15)
      screen.text("density: ".. density)
      else
      screen.move(74,20)
      screen.level(0)
      screen.text("density: ".. density)
      end
  screen.update()
end

  function enc(n,d)
    if n == 2 then
      if d > 0 then
        which = (which + 1) % 5
        else
      which = (which - 1) % 5
      end
      params:set("which",which)
      redraw()
      end
      if n == 3 then
        if d > 0 then
          engine.glitch(which)
          glitched[which] = true
          redraw()
          end
          if d < 0 then
            engine.normal(which)
            glitched[which] = false
            redraw()
            end
        end
    end

function automode_start()
  automode = true
  timer:start()
  redraw()
end

function automode_stop()
  automode = false
  timer:stop()
  for i=0,4 do
        engine.densitySet(i,1)
        end
  redraw()
end

  
  function key(n,z)
    if n == 1 then
      if z == 1 then
        alt = true
        elseif z == 0 then
          alt = false
          end
        end
    if n == 2 then
      if alt == true then
        --automode_start()
        params:set("auto mode",2)
      elseif alt == false then
        if z == 1 then
        record_buffer(which)
        elseif z == 0 then
          play_buffer(which)
          end
        end
      end
      if n == 3 then
        if alt == true then
        --automode_stop()
        params:set("auto mode",1)
        elseif alt == false then
          clear_buffer(params:get("which"))
          end
        end
      end
    
function redraw()
  screen.clear()
  screen.aa(1)
  screen.move(0, 8)
  screen.font_size(8)
  screen.level(10)
  screen.text("Glitch Looper")
  screen_update_channels()
  screen.update()
end

function record_buffer(which)
  loopPlaying[which] = false
  recording[which] = true
  engine.recStart(which)
  redraw()
end

function play_buffer(which)
  engine.recEnd(which)
  engine.amp(which, 1.0)
  recording[which] = false
  loopPlaying[which] = true
  redraw()
end

function clear_buffer(which)
  recording[which] = false
  engine.amp(which, 0.0)
  loopPlaying[which] = false
  redraw()
end

function cleanup()
  audio.monitor_stereo()
end

  
