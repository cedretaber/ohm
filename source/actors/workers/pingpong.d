module ohm.actors.workers.pingpong;

import std.concurrency, std.variant;

import ohm.app, ohm.actors.io, ohm.actors.admin;

void pingPong(Tid ioHolder)
{
    for(auto loop = true; loop;)
        receive(
            (Tid tid, RunCommand _rc) { if(tid == ownerTid) ioHolder.send(WritingMessage.make("pong!")); },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; },
            (Variant any) {}
        );
}

void countWorker(Tid writer) {}

void timerWorker(Tid writer) {}

void echoWorker(Tid writer) {}