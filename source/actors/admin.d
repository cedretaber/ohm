module ohm.actors.admin;

import
    std.concurrency, std.array, std.regex, std.variant,
    std.typecons, std.algorithm.searching, std.algorithm.iteration;

// import std.stdio;

import ohm.app, ohm.actors.io, ohm.actors.workers;

enum keywords = "exit quit echo ping set delete count timer".split(" ");

enum setState = ctRegex!(r"^set (\w+) (.+)$");
enum deleteState = ctRegex!(r"^delete (\w+)$");
enum commandState1 = ctRegex!(r"^\w+$");
enum commandState2 = ctRegex!(r"^(\w+) (.+)$");
enum commandNumber = ctRegex!(r"^(\w+) (\d+)$");

alias Capt = Captures!(string, size_t);

void actorsAdmin(Tid ioHolder)
{
    auto workers = [
        "ping": spawn(&pingPong, ioHolder),
        "echo": spawn(&echoWorker, ioHolder)
    ];

    void receiveMessage(string msg)
    {
        bool isKeywordOrDeleteIfExist(string com)
        {
            if(keywords.any!(e => e == com)) return true;

            auto tid = (com in workers);
            if(tid !is null)
            {
                workers.remove(com);
                (*tid).prioritySend(thisTid, TERMINATE);
            }
            return false;
        }

        [
            tuple(setState, (Capt c) {
                auto com = c[1];
                if(isKeywordOrDeleteIfExist(com)) return;

                workers[com] = spawn(&speaker, ioHolder, c[2]);
            }),
            tuple(deleteState, (Capt c) { isKeywordOrDeleteIfExist(c[1]); }),
            tuple(commandState1, (Capt c) {
                auto com = c.hit;
                auto tid = (com in workers);
                if(tid !is null) (*tid).send(thisTid, RUNCOMMAND);
            }),
            tuple(commandState2, (Capt c) {
                auto com = c[1];
                auto arg = c[2];

                auto tid = (com in workers);
                if(tid !is null) (*tid).send(WorkersArgument.make(arg));
            })
        ].each!((tup) {
            if(auto cap = msg.matchFirst(tup[0]))
            {
                tup[1](cap);
                return;
            }
        });
    }

    for(auto loop = true; loop;)
        receive(
            (immutable ReadMessage message) { receiveMessage(message.msg); },
            (Tid tid, Terminate _t) {
                if(tid == ownerTid)
                {
                    workers.values.each!(c => c.prioritySend(thisTid, TERMINATE));
                    loop = false;
                }
            }
        );
}

struct RunCommand {}
enum RUNCOMMAND = RunCommand();

string constructor(string arg)
{return "
    string " ~ arg ~ ";

    this(string " ~ arg ~ ") immutable
    {
    this." ~ arg ~ " = " ~ arg ~ ";
    }

    static auto make(string " ~ arg ~ ")
    {
    return new immutable(WorkersArgument)(" ~ arg ~ ");
    }
";}

immutable
class WorkersArgument
{
    mixin(constructor("arg"));
}

immutable
class TerminatedSignal
{
    mixin(constructor("name"));
}