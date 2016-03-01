module ohm.actors.io;

import std.stdio, std.string, std.concurrency;

import ohm.app;

void ioWriter(Tid owner)
{
	auto loop = true;
	while(loop)
	{
		receive(
			(immutable WritingMessage msg) { writeln(msg.msg); },
			(Tid tid, Terminate t) { if(tid == owner) loop = false; }
		);
	}
	owner.send(thisTid, TERMINATED);
}

void ioReader(Tid owner)
{
	auto loop = true;
	while(loop)
	{
		owner.send(new immutable(ReadMessage)(readln.chomp));
		auto innerLoop = true;
		while(innerLoop)
		{
			receive(
				(Tid tid) { if(tid == owner) innerLoop = false; },
				(Tid tid, Terminate t) { if(tid == owner) loop = innerLoop = false; }
			);
		}
	}
	owner.send(thisTid, TERMINATED);
}

immutable abstract
class IOMessage {}

template Constractors()
{
	string msg;

	this(string msg)
	{
		this.msg = msg;
	}

	this()
	{
		this("");
	}
}

class WritingMessage : IOMessage
{
	mixin Constractors;
}

class ReadMessage : IOMessage
{
	mixin Constractors;
}
