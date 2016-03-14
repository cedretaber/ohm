module ohm.actors.workers.timer;

import
    std.concurrency, std.variant, std.regex,
    std.conv, std.algorithm.iteration;
import core.time;

import ohm.app, ohm.actors.io, ohm.actors.admin;

enum counterReg = ctRegex!r"^(\d+) (.+)$";

void timerHolder(Tid ioHolder)
{
    Tid[immutable Timer] table;

    for(auto loop = true; loop;)
        receive(
            (immutable ReadMessage rm) {
                with(rm)
                {
                    if(auto cap = msg.matchFirst(counterReg))
                    {
                        auto timer = new immutable(Timer)(cap[1].to!int, cap[2]);
                        table[timer] = spawn(timer, ioHolder);
                    }
                }
            },
            (immutable Timer timer) {
                if((timer in table) !is null)
                {
                    table[timer].send(thisTid, TERMINATE);
                    table.remove(timer);
                }
            },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; },
            (Variant any) {}
        );

    table.values.each!(c => c.prioritySend(thisTid, TERMINATE));
}

immutable
class Timer
{
    long len;
    string msg;

    this(long len, string msg) immutable
    {
        this.len = len;
        this.msg = msg;
    }

    void opCall(Tid ioHolder)
    {
        receiveTimeout(
            len.dur!"seconds",
            (Tid tid, Terminate _t) { if(tid == ownerTid) return; }
        );
        ioHolder.send(WritingMessage.make(msg));
        ownerTid.send(this);
    }
}
