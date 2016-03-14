module ohm.actors.workers.timer;

import std.concurrency, std.variant;
import core.time;

import ohm.app, ohm.actors.io, ohm.actors.admin;

immutable
class Tiemr
{
    string name;
    long len;
    string msg;

    this(string name, long len, string msg) immutable
    {
        this.name = name;
        this.len = len;
        this.msg = msg;
    }

    void opCall(Tid ioHolder)
    {
        bool isTerminated;
        for(auto loop = true; loop;)
        {
            auto ignore = true;
            receiveTimeout(
                len.dur!"seconds",
                (Tid tid, Terminate _t) {
                    if(tid == ownerTid)
                    {
                        loop = false;
                        isTerminated = true;
                    }
                },
                (Variant any) { ignore = false; }
            );
            if(isTerminated && !ignore)
            {
                ioHolder.send(WritingMessage.make(msg));
                ownerTid.send(TerminatedSignal.make(name));
                loop = false;
            }
        }
    }
}
