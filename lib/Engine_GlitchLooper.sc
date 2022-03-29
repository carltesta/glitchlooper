Engine_GlitchLooper : CroneEngine {

	//var in=0;
	//var out=0;
	var amp=1;
	var <densityBus;
	var <analysis;
	var <buffers;
	var <counterBuses;
	var <startEndBus;
	var <loopers;
	var <rands;
	var <record;

// this is your constructor. the 'context' arg is a CroneAudioContext.
// it provides input and output busses and groups.
// see its implementation for details.
	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

// this is called when the engine is actually loaded by a script.
// you can assume it will be called in a Routine,
//  and you can use .sync and .wait methods.
	alloc {
		var s = Server.default;
		//Add SynthDefs
		//Looper Synth

SynthDef(\record, {|in, out, buf|
	var input = In.ar(in);
	var endPos = Gate.ar(Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf)), \run.tr(0));
	FreeSelf.kr(\run.tr(0),RecordBuf.ar(input, buf, 0, 1, 0, 1, 0, 0, 2));
	Out.kr(out, endPos);
}).add;

SynthDef(\randomPosition, {|buf, density=1, endValue, out|
	var randTrigger = Dust.kr(density);
	var randomStartFrame = TIRand.kr(0, endValue, randTrigger);
	var randomEndFrame = TIRand.kr(randomStartFrame, endValue, randTrigger);
	Out.kr(out, [randomStartFrame, randomEndFrame]);
}).add;

SynthDef(\onsets, {|in, out, win=4|
		var input = In.ar(in);
		var buf = LocalBuf.new(512,1);
		var onsets = Onsets.kr(FFT(buf, input));
		var stats = OnsetStatistics.kr(onsets, win);
		var value = (stats[0]/win);
		Out.kr(out, value);
	}).add;

SynthDef(\loop, {|out, buf, startLoop=0, endLoop, pan=0, amp=0|
	var sound = LoopBuf.ar(1, buf, 1, 1, 0, startLoop, endLoop, 1);
	Out.ar(out, Pan2.ar(sound, pan, amp));
}).add;
		s.sync;

		//Setup Buffers, etc

		//Setup for Looper
		buffers = Buffer.allocConsecutive(5, s, (10*Server.default.sampleRate).nextPowerOfTwo, 1);
counterBuses = Bus.control(s, 5);
startEndBus = Bus.control(s, 10);
densityBus = Bus.control(s, 1);
analysis = Synth.new(\onsets, [\in, context.in_b[0].index, \out, densityBus.index, \win, 4], context.ig, \addAfter);
loopers = 5.collect({|n| Synth.new(\loop, [\out, context.out_b.index, \buf, buffers[n].bufnum, \endLoop, counterBuses.subBus(n).asMap], context.xg, \addToTail )});
		rands = 5.collect({|n| Synth.new(\randomPosition, [\buf, buffers[n].bufnum, \density, 1 /*densityBus.asMap*/, \out, startEndBus.subBus(n*2), \endValue, counterBuses.subBus(n).asMap],context.xg, \addToHead)});
record = Array.fill(5, {0});

		s.sync;

// this is how you add "commands",
// which is how the lua interpreter controls the engine.
// the format string is analogous to an OSC message format string,
// and the 'msg' argument contains data.

		this.addCommand("test", "ii", {|msg|
			msg.postln;
		});

		this.addCommand("amp", "if", {|msg|
			amp = msg[2];
			loopers[msg[1]].set(\amp, msg[2]);
		});

		this.addCommand("pan", "if", {|msg|
			loopers[msg[1]].set(\pan, msg[2]);
		});

		this.addCommand("densitySet", "if", {|msg|
			rands[msg[1]].set(\density, msg[2]);
                });

		this.addCommand("recStart", "i", {|msg|
			"record start".postln;
			loopers[msg[1]].set(\amp, 0);
		//loopers[which].changed(\amp, 0);
		buffers[msg[1]].zero;
		record[msg[1]] = Synth.new(\record, [\in, context.in_b[0].index, \buf, buffers[msg[1]].bufnum, \out, counterBuses.subBus(msg[1])], context.ig, \addAfter);
		});

		this.addCommand("recEnd", "i", {|msg|
			"record end".postln;
		//End Recording
		record[msg[1]].set(\run, 1);
		loopers[msg[1]].set(\amp, amp);
		//loopers[which].changed(\amp, 0);
		});

		this.addCommand("normal", "i", {|msg|
		loopers[msg[1]].set(\startLoop, 0, \endLoop, counterBuses.subBus(msg[1]).asMap);
		//loopers[which].changed(\startLoop, 0);
		});

		this.addCommand("glitch", "i", {|msg|
		loopers[msg[1]].set(\startLoop, startEndBus.subBus(msg[1]*2).asMap, \endLoop, startEndBus.subBus((msg[1]*2)+1).asMap);
		//loopers[which].changed(\startLoop, 1);
		});

/// this is how you add a "poll", which is how to send data back to lua,
// triggering a callback.
// by default, a poll is periodically evaluated with a given function.
// this function just returns a random number.
		this.addPoll("density", {densityBus.getSynchronous});

/// here is a non-periodic poll, which we can arbitrarily trigger.
// notice that it has no function argument.
                //baz_poll = this.addPoll("baz", periodic:false);

	}

	free {
             // here you should free resources (e.g. Synths, Buffers &c)
// and stop processes (e.g. Routines, Tasks &c)
            buffers.free;
			counterBuses.free;
			startEndBus.free;
		    densityBus.free;
		analysis.free;
		rands.do({|n| n.free});
		loopers.do({|n| n.free});
	}

}
