module ohm.actors.workers.pingpong;

import std.concurrency, std.variant;

import ohm.app, ohm.actors.io, ohm.actors.admin;

void pingPong(Tid owner, Tid ioHolder)
{
	for(auto loop = true; loop;)
		receive(
			(Tid tid, RunCommand _rc) { if(tid == ownerTid) ioHolder.send(WritingMessage.make("pong!")); },
			(Tid tid, Terminate _t) { if(tid == owner) loop = false; },
			(Variant any) {}
		);
}

void countWorker(Tid owner, Tid writer) {}

void timerWorker(Tid owner, Tid writer) {}