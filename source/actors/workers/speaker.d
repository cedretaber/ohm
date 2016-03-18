module ohm.actors.workers.speaker;

import std.concurrency, std.variant;

import ohm.app, ohm.actors.admin, ohm.actors.io;

void speaker(Tid ioHolder, string msg) {
    for(auto loop = true; loop;)
        receive(
            (Tid tid, RunCommand _rc) { if(tid == ownerTid) ioHolder.send(new WritingMessage(msg)); },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; },
            (Variant any) {}
        );
}
