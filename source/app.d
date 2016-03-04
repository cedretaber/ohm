module ohm.app;

import std.stdio, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.actors.io, ohm.actors.admin;

void main()
{
	auto ioHolder = spawn(&ioHolder, thisTid);
	auto pp = spawn(&pingPong, thisTid, ioHolder);

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
						pp.send(message);
					}
				}
			}
		);

	auto hts = [ioHolder, pp];
	hts.each!(h => h.prioritySend(thisTid, TERMINATE));
}

struct Terminate {}
enum TERMINATE = Terminate();

struct Terminated {}
enum TERMINATED = Terminated();
