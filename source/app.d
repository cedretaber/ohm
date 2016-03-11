module ohm.app;

import std.stdio, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.actors.io, ohm.actors.admin;

void main()
{
    auto ioHolder = spawn(&ioHolder);
    auto actorsAdmin = spawn(&actorsAdmin, ioHolder);

    for(auto loop = true; loop;)
        receive(
            (immutable ReadMessage message) {
                with(message)
                {
                    if(msg == "exit" || msg == "quit")
                        loop = false;
                    else
                    {
                        ioHolder.send(thisTid, READCONTINUE);
                        actorsAdmin.send(message);
                    }
                }
            }
        );

    [ioHolder, actorsAdmin].each!(h => h.prioritySend(thisTid, TERMINATE));
}

struct Terminate {}
enum TERMINATE = Terminate();
