module ohm.app;

import std.stdio, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.actors.io, ohm.actors.admin;

void main()
{
	auto writer = spawn(&ioWriter, thisTid);
	auto reader = spawn(&ioReader, thisTid);

	auto pp = spawn(&pingPong, thisTid, writer);

	auto hts = [writer, reader, pp];

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
							reader.send(thisTid);
							pp.send(message);
						}
					}
				}
		);
	}
	hts.each!(h => h.send(thisTid, Terminate.T));

	auto ct = 3;
	while(ct)
	{
		auto tid = receiveOnly!(Tid, Terminated)[0];
		if(hts.any!(h => h == tid)) --ct;
	}
}

enum Terminate { T }
enum Terminated { T }