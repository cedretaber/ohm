module ohm.actors.workers.counter;

import std.concurrency, std.variant, std.conv;
import core.time : dur;

import ohm.app, ohm.actors.io, ohm.actors.admin;

void countWorker(Tid ioHolder, string name, int cnt)
{
    while(cnt--)
    {
        receiveTimeout(
            1.dur!"seconds",
            (Tid tid, Terminate _t) { if(tid == ownerTid) cnt = 0; },
            (Variant any) {}
        );
        ioHolder.send(WritingMessage.make(cnt.to!string));
    }
    ownerTid.send(TerminatedSignal.make(name));
}