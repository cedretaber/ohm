module ohm.actors.admin;

import std.concurrency, std.array;

import ohm.app, ohm.actors.io;

enum keywords = "exit quit echo set delete".split(" ");

void admin(Tid owner)
{
}

void pingPong(Tid owner, Tid writer)
{
	auto loop = true;
	while(loop)
	{
		receive(
				(immutable ReadMessage message) { with(message) if(msg == "ping") writer.send(new immutable(WritingMessage)("pong!")); },
				(Tid tid, Terminate t) { if(tid == owner) loop = false; }
		);
	}
	owner.send(thisTid, Terminated.T);
}