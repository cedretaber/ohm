module ohm.actors.io;

import std.stdio, std.string, std.concurrency, std.algorithm.searching, std.algorithm.iteration;

import ohm.app;

void ioHolder(Tid owner)
{
	auto writer = spawn(&ioWriter, thisTid);
	auto reader = spawn(&ioReader, thisTid);

	auto loop = true;
	while(loop)
	{
		receive(
			(immutable WritingMessage msg) { writer.send(msg); },
			(immutable ReadMessage msg) { owner.send(msg); },
			(Tid tid, ReadContinue readContinue) { if(tid == owner) reader.send(thisTid); },
			(Tid tid, Terminate terminate) {
				if(tid == owner)
				{
					writer.send(thisTid, terminate);
					reader.send(thisTid, terminate);
					loop = false;
				}
			}
		);
	}

	auto children = [writer: true, reader: true];
	while(children.values.any)
		receive((Tid tid, Terminated _t) { children[tid] = false; });
	owner.send(thisTid, TERMINATED);
}

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

struct ReadContinue {}
enum READCONTINUE = ReadContinue();