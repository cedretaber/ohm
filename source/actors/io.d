module ohm.actors.io;

import std.stdio, std.string, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.app;

void ioHolder(Tid owner)
{
	auto writer = spawn(&ioWriter, thisTid);
	auto reader = spawn(&ioReader, thisTid);

	for(auto loop = true; loop;)
		receive(
			(immutable WritingMessage msg) { writer.send(msg); },
			(immutable ReadMessage msg) { owner.send(msg); },
			(Tid tid, ReadContinue readContinue) { if(tid == owner) reader.send(thisTid, readContinue); },
			(Tid tid, Terminate terminate) {
				if(tid == owner)
				{
					writer.prioritySend(thisTid, terminate);
					reader.prioritySend(thisTid, terminate);
					loop = false;
				}
			}
		);
}

void ioWriter(Tid owner)
{
	for(auto loop = true; loop;)
		receive(
			(immutable WritingMessage msg) { writeln(msg.msg); },
			(Tid tid, Terminate _t) { if(tid == owner) loop = false; }
		);
}

void ioReader(Tid owner)
{
	for(auto loop = true; loop;)
	{
		owner.send(ReadMessage.make(readln.chomp));
		for(auto innerLoop = true; innerLoop;)
			receive(
				(Tid tid, ReadContinue _r) {if(tid == owner) innerLoop = false;},
				(Tid tid, Terminate _t) {if(tid == owner) loop = innerLoop = false;}
			);
	}
}

immutable abstract
class IOMessage {}

template Constractors()
{
	string msg;

	this(string msg = "")
	{
		this.msg = msg;
	}

	static auto make(string msg)
	{
		return new immutable(typeof(this))(msg);
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

struct ReadContinue {}
enum READCONTINUE = ReadContinue();