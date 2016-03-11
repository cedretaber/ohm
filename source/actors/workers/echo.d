module ohm.actors.workers.echo;

import std.concurrency, std.variant;

import ohm.app, ohm.actors.io, ohm.actors.admin;

void echoWorker(Tid ioHolder)
{
    for(auto loop = true; loop;)
        receive(
            (immutable WorkersArgument arg) { ioHolder.send(WritingMessage.make(arg.arg)); },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; },
            (Variant any) {}
        );
}