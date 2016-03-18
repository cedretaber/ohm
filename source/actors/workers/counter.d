module ohm.actors.workers.counter;

import std.concurrency, std.variant, std.conv, std.regex;
import core.time : dur;

import ohm.app, ohm.actors.io, ohm.actors.admin;

enum startReg = ctRegex!r"^start (\d+)$";
enum stopReg = ctRegex!r"^stop$";

void counterHolder(Tid ioHolder)
{
    bool hasCounter;
    Tid counter;

    void stopIfExist()
    {
        if(hasCounter) counter.prioritySend(thisTid, TERMINATE);
        hasCounter = false;
    }

    for(auto loop = true; loop;)
        receive(
            (ReadMessage rm) {
                with(rm)
                {
                    if(auto cap = msg.matchFirst(startReg))
                    {
                        stopIfExist();
                        counter = spawnLinked(&countWorker, ioHolder, cap[1].to!int);
                        hasCounter = true;
                    }
                    else if(msg.matchFirst(stopReg))
                        stopIfExist();
                }
            },
            (Tid tid, Terminate _t) {
                if(tid == ownerTid)
                {
                    stopIfExist();
                    loop = false;
                }
            },
            (LinkTerminated _lt) { hasCounter = false; },
            (Variant any) {}
        );
}

void countWorker(Tid ioHolder, int cnt)
{
    while(cnt-- > 0)
    {
        ioHolder.send(new WritingMessage(cnt.to!string));
        receiveTimeout(
            1.dur!"seconds",
            (Tid tid, Terminate _t) { if(tid == ownerTid) cnt = 0; }
        );
    }
}
