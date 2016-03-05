module ohm.actors.admin;

import std.concurrency, std.array, std.regex, std.variant, std.typecons, std.algorithm.searching, std.algorithm.iteration;

import ohm.app, ohm.actors.io, ohm.actors.workers.pingpong;

enum keywords = "exit quit echo ping set delete count timer".split(" ");

enum setState = ctRegex!(r"^set (\w+) (.*)$");
enum deleteState = ctRegex!(r"^delete (\w+)$");
enum commandState1 = ctRegex!(r"^\w+$");
enum commandState2 = ctRegex!(r"^(\w+) (\w+)$");

alias Capt = Captures!(string, size_t);

void actorsAdmin(Tid owner, Tid ioHolder)
{
        auto workers = [
                "ping": spawn(&pingPong, thisTid, ioHolder),
                "count": spawn(&countWorker, thisTid, ioHolder),
                "timer": spawn(&timerWorker, thisTid, ioHolder)
        ];

    void receiveMessage(string msg)
    {
        bool isKeywordOrDeleteIfExist(string com)
        {
            if(keywords.find(com)) return true;

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

                workers[com] = spawn(
                    (Tid owner, Tid ioHolder, string msg) {
                        for(auto loop = true; loop;)
                            receive(
                                (Tid tid, RunCommand _rc) { if(tid == owner) ioHolder.send(WritingMessage.make(msg)); },
                                (Tid tid, Terminate _t) { if(tid == owner) loop = false; },
                                (Variant any) {}
                            );
                    },
                    thisTid, ioHolder, c[2]
                );
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
                if(tid == owner)
                {
                    workers.values.each!(c => c.prioritySend(thisTid, TERMINATE));
                    loop = false;
                }
            }
                        );
}

struct RunCommand {}
enum RUNCOMMAND = RunCommand();

class WorkersArgument {
    string arg;

    this(string arg) immutable
    {
        this.arg = arg;
    }

    static auto make(string arg)
    {
        return new immutable(WorkersArgument)(arg);
    }
}