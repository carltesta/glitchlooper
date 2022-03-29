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
local util = require 'util'
local selected_channels = {1}
local loopPlaying = {false, false, false, false, false}
local recording = {false, false, false, false, false}
local glitched = {false, false, false, false, false}
local which = 0
local alt = false
local automode = false
density = 0

function init()
  print("glitched looper")
  audio.level_monitor(1)
  audio.monitor_mono()
  
  density_poll = poll.set("density", function(x) density = x end)
  density_poll:start()
  
  timer = metro.init(auto_mode,1,-1)
  
  --params
  params:add_separator("auto mode settings")
  params:add_option("auto mode","auto mode",{"off","on"},1)
  params:set_action("auto mode", function(x) if x == 2 then automode_start() elseif x == 1 then automode_stop() end end )
  params:add_control("min_wait_time","minimum wait time",controlspec.new(0.1,10,'lin',0.1,0.5,'sec'))
  params:add_control("max_wait_time","maximum wait time",controlspec.new(10,100,'lin',0.1,10,'sec'))
  params:add_option("density_polarity", "density",{"increases wait time","decreases wait time"},1)
  params:add_control("glitch_prob", "glitch probability",controlspec.new(0,1,'lin',0.1,0.5))
  params:add_control("stop_playing_prob", "stop play probability",controlspec.new(0,1,'lin',0.1,0.5))
  
  params:add_separator("loop settings")
  params:add_number("which","buffer",0,4,0,nil,true)
  params:set_action("which",function(x) which = x; redraw() end)
  
  for i=0,4 do
  params:add_option("state" .. i,"state: " .. i,{"cleared","recording","playing"},1)
  params:set_action("state" .. i, function(x) 
   if x == 1 then clear_buffer(i) 
  elseif x == 2 then record_buffer(i)
  elseif x == 3 then play_buffer(i)
  end end)
  end
  
  for i=0,4 do
  params:add_option("mode" .. i,"mode: " .. i,{"normal","glitched"},1)
  params:set_action("mode" .. i, function(x) 
   if x == 1 then set_normal(i) 
  elseif x == 2 then set_glitched(i)
  end end)
  end
  
  for i=0,4 do
  params:add_control("amp" .. i,"amp: " .. i,controlspec.AMP)
  params:set_action("amp" .. i, function(x) engine.amp(i,x) end)
  params:set("amp" .. i, 1)
  end
  
  for i=0,4 do
  params:add_control("pan" .. i,"pan: " .. i,controlspec.PAN)
  params:set_action("pan" .. i, function(x) engine.pan(i,x) end)
  params:set("pan" .. i, 0)
  end
  
  params:add_separator()
  
  params:add_trigger("reset","reset")
  params:set_action("reset",function(x) reset() end)
end

auto_mode = function()
    print("density " .. density)
    print("running auto mode")
    --choose new channel for iteration
    params:set("which",(math.random(5)-1))
    print("chosen new which")
    print(which)
    if recording[which] == false then
    -- start recording
    params:set("state" .. which, 2) -- record_buffer
    --wait longer if density is higher or shorter if density polarity is activated
    wait_based_on_density()
    elseif recording[which] == true then
    -- stop recording and begin playback
    params:set("state" .. which, 3) -- play_buffer
    end
    
    -- choose normal or glitch based on glitch probability
    if math.random() <= params:get("glitch_prob") then
      params:set("mode" .. which, 2) -- glitch mode
      else
      params:set("mode" .. which, 1) -- normal mode
      end
      -- maybe stop playing based on stop playing probability
      if loopPlaying[which] == true then
      if math.random() <= params:get("stop_playing_prob") then
          params:set("state" .. which, 1) -- clear_buffer
          end
        end
    -- wait
    wait_based_on_density()
  end

function screen_update_channels()
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
      local value = params:get("which")
      if d > 0 then
        value = (value + 1) % 5
        else
      value = (value - 1) % 5
      end
      params:set("which",value)
      redraw()
      end
      if n == 3 then
        if d > 0 then
          params:set("mode" .. which,2) -- set_glitched
          end
          if d < 0 then
            params:set("mode" .. which, 1) -- set_normal
            end
        end
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
        params:set("state" .. which, 2) -- record_buffer
        elseif z == 0 then
          params:set("state" .. which, 3) -- play_buffer
          end
        end
      end
      if n == 3 then
        if alt == true then
        --automode_stop()
        params:set("auto mode",1)
        elseif alt == false then
          params:set("state" .. which, 1) -- clear_buffer
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

-- new functions

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
  print("loop" .. which .. "cleared")
  redraw()
end

function set_normal(which)
  engine.normal(which)
  glitched[which] = false
  redraw()
end

function set_glitched(which)
  engine.glitch(which)
  glitched[which] = true
  redraw()
end

function wait_based_on_density()
  if params:get("density_polarity") == 1 then
    --increase wait time
    local waittime = util.linlin(0,15,params:get("min_wait_time"),params:get("max_wait_time"),density)
    timer.time = waittime
  elseif params:get("density_polarity") == 2 then
    local waittime = util.linlin(15,0,params:get("max_wait_time"),params:get("min_wait_time"),density)
    timer.time = waittime
  end
end

function reset()
  for i=0,4 do
    params:set("state" .. i, 1) -- clear_buffer
    params:set("mode" .. i, 1) -- set_normal
  end
  params:set("auto mode", 1)
  params:set("which", 0)
end

function cleanup()
  audio.monitor_stereo()
end
