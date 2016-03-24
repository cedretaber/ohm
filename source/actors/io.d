module ohm.actors.io;

import std.stdio, std.string, std.concurrency, std.algorithm.searching, std.algorithm.iteration, std.variant;

import ohm.app;

void ioHolder()
{
    auto writer = spawn(&ioWriter);
    auto reader = spawn(&ioReader);

    for(auto loop = true; loop;)
        receive(
            (WritingMessage msg) { writer.send(msg); },
            (ReadMessage msg) { ownerTid.send(msg); },
            (Tid tid, ReadContinue rc) { if(tid == ownerTid) reader.send(thisTid, rc); },
            (Tid tid, Terminate terminate) { if(tid == ownerTid) loop = false; }
        );

    [writer, reader].each!(c => c.prioritySend(thisTid, TERMINATE));
}

void ioWriter()
{
    for(auto loop = true; loop;)
        receive(
            (WritingMessage msg) { writeln(msg.msg); },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; }
        );
}

void ioReader()
{
    for(auto loop = true; loop;)
    {
        ownerTid.send(new ReadMessage(readln.chomp));
        for(auto innerLoop = true; innerLoop;)
            receive(
                (Tid tid, ReadContinue _r) { if(tid == ownerTid) innerLoop = false; },
                (Tid tid, Terminate _t) { if(tid == ownerTid) loop = innerLoop = false; },
                (Variant _any) {}
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

template Constructors()
{
    this(string msg = "")
    {
        super(msg);
    }
}

immutable
class MutableWritingMessage : IOMessage
{
    mixin Constructors;
}
alias WritingMessage = immutable MutableWritingMessage;

immutable
class MutableReadMessage : IOMessage
{
    mixin Constructors;
}
alias ReadMessage = immutable MutableReadMessage;

struct ReadContinue {}
enum READCONTINUE = ReadContinue();
