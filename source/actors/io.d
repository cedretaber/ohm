module ohm.actors.io;

import std.stdio, std.string, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.app;

void ioHolder()
{
    auto writer = spawn(&ioWriter);
    auto reader = spawn(&ioReader);

    for(auto loop = true; loop;)
        receive(
            (immutable WritingMessage msg) { writer.send(msg); },
            (immutable ReadMessage msg) { ownerTid.send(msg); },
            (Tid tid, ReadContinue rc) { if(tid == ownerTid) reader.send(thisTid, rc); },
            (Tid tid, Terminate terminate) {
                if(tid == ownerTid)
                {
                    writer.prioritySend(thisTid, terminate);
                    reader.prioritySend(thisTid, terminate);
                    loop = false;
                }
            }
        );
}

void ioWriter()
{
    for(auto loop = true; loop;)
        receive(
            (immutable WritingMessage msg) { writeln(msg.msg); },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; }
        );
}

void ioReader()
{
    for(auto loop = true; loop;)
    {
        ownerTid.send(ReadMessage.make(readln.chomp));
        for(auto innerLoop = true; innerLoop;)
            receive(
                (Tid tid, ReadContinue _r) {if(tid == ownerTid) innerLoop = false;},
                (Tid tid, Terminate _t) {if(tid == ownerTid) loop = innerLoop = false;}
            );
    }
}

immutable abstract
class IOMessage
{
    string msg;

    this(string msg)
    {
        this.msg = msg;
    }
}

template Constractors()
{
    this(string msg = "")
    {
        super(msg);
    }

    static auto make(string msg)
    {
        return new immutable(typeof(this))(msg);
    }
}

immutable
class WritingMessage : IOMessage
{
    mixin Constractors;
}

immutable
class ReadMessage : IOMessage
{
    mixin Constractors;
}

struct ReadContinue {}
enum READCONTINUE = ReadContinue();