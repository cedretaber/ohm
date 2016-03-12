module ohm.actors.workers.timer;

import std.concurrency, std.variant;
import core.time;

import ohm.app, ohm.actors.io, ohm.actors.admin;

void timerWorker(Tid ioHolder, string name, long len, string msg)
{
    for(auto loop = true; loop;)
        receiveTimeout(
            len.dur!"seconds",
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; },
            (Variant any) {}
        );
    ioHolder.send(WritingMessage.make(msg));
    ownerTid.send(TerminatedSignal.make(name));
}
