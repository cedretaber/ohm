module ohm.app;

import std.stdio, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.actors.io, ohm.actors.admin;

void main()
{
	auto ioHolder = spawn(&ioHolder, thisTid);
	auto pp = spawn(&pingPong, thisTid, ioHolder);

	auto hts = [ioHolder, pp];

	auto loop = true;
	while(loop)
	{
		receive(
			(immutable ReadMessage message) {
				with(message)
				{
					if(msg == "exit" || msg == "quit")
						loop = false;
					else
					{
						ioHolder.send(thisTid, READCONTINUE);
						pp.send(message);
					}
				}
			}
		);
	}

	bool[Tid] states;
	hts.each!((h) {
		h.send(thisTid, TERMINATE);
		states[h] = true;
	});
	while(states.values.any)
		receive((Tid tid, Terminated _t) { states[tid] = false; });
}

struct Terminate {}
enum TERMINATE = Terminate();

struct Terminated {}
enum TERMINATED = Terminated();
