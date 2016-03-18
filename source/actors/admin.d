module ohm.actors.admin;

import
    std.concurrency, std.array, std.regex, std.variant,
    std.typecons, std.algorithm.searching, std.algorithm.iteration;

import ohm.app, ohm.actors.io, ohm.actors.workers;

enum keywords = "exit quit echo ping set delete counter timer".split(" ");

enum setState = ctRegex!r"^set (\w+) (.+)$";
enum deleteState = ctRegex!r"^delete (\w+)$";
enum echoState = ctRegex!r"^echo (.+)$";
enum timerState = ctRegex!r"^timer (.+)$";
enum counterState = ctRegex!r"^counter (.+)$";
enum commandState = ctRegex!r"^\w+$";

alias Capt = Captures!(string, size_t);

void actorsAdmin(Tid ioHolder)
{
    auto workers = [
        "ping": spawn(&pingPong, ioHolder),
        "echo": spawn(&echoWorker, ioHolder),
        "counter": spawn(&counterHolder, ioHolder),
        "timer": spawn(&timerHolder, ioHolder)
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
            tuple(echoState, (Capt c) { workers["echo"].send(WorkersArgument.make(c[1])); }),
            tuple(counterState, (Capt c) { workers["counter"].send(ReadMessage.make(c[1])); }),
            tuple(timerState, (Capt c) { workers["timer"].send(ReadMessage.make(c[1])); }),
            tuple(commandState, (Capt c) {
                auto com = c.hit;
                auto tid = (com in workers);
                if(tid !is null) (*tid).send(thisTid, RUNCOMMAND);
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

immutable
class WorkersArgument
{
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
