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
alias t = tuple;

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
        void deleteIfExist(string com)
        {
            auto tid = (com in workers);
            if(tid !is null)
            {
                workers.remove(com);
                (*tid).prioritySend(thisTid, TERMINATE);
            }
        }

        [
            t(setState, (Capt c) {
                auto com = c[1];
                if(keywords.any!(e => e == com)) return;

                deleteIfExist(com);
                workers[com] = spawn(&speaker, ioHolder, c[2]);
            }),
            t(deleteState, (Capt c) { deleteIfExist(c[1]); }),
            t(echoState, (Capt c) { workers["echo"].send(new WorkersArgument(c[1])); }),
            t(counterState, (Capt c) { workers["counter"].send(new ReadMessage(c[1])); }),
            t(timerState, (Capt c) { workers["timer"].send(new ReadMessage(c[1])); }),
            t(commandState, (Capt c) {
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
            (ReadMessage message) { receiveMessage(message.msg); },
            (Tid tid, Terminate _t) { if(tid == ownerTid) loop = false; }
        );

    workers.values.each!(c => c.prioritySend(thisTid, TERMINATE));
}

struct RunCommand {}
enum RUNCOMMAND = RunCommand();

immutable
class MutableWorkersArgument
{
    string arg;

    this(string arg) immutable
    {
        this.arg = arg;
    }
}
alias WorkersArgument = immutable MutableWorkersArgument;
