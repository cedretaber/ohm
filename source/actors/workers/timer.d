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
            (ReadMessage rm) {
                with(rm)
                {
                    if(auto cap = msg.matchFirst(counterReg))
                    {
                        auto timer = new Timer(cap[1].to!int, cap[2]);
                        table[timer] = spawn(timer, ioHolder);
                    }
                }
            },
            (Timer timer) {
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
class MutableTimer
{
    long len;
    string msg;

    this(long len, string msg) immutable
    {
        this.len = len;
        this.msg = msg;
    }

    void opCall(Tid ioHolder) immutable
    {
        receiveTimeout(
            len.dur!"seconds",
            (Tid tid, Terminate _t) { if(tid == ownerTid) return; }
        );
        ioHolder.send(new WritingMessage(msg));
        ownerTid.send(this);
    }
}
alias Timer = immutable MutableTimer;
