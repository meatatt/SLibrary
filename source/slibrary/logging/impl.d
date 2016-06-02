module slibrary.logging.impl;

import std.meta: AliasSeq;
import std.datetime: SysTime;
import core.stdc.errno: errno;
import core.atomic: atomicLoad,atomicStore;
import std.concurrency: Tid,spawn,receive,OwnerTerminated;

import slibrary.logging.api: AF=ArgFlags,TraceInfo;

alias slibrary.logging.impl defaultImpl;

private shared Tid _daemonTid;
Tid loggingDaemon(){
	return atomicLoad(_daemonTid);
}
shared static this(){
	atomicStore(_daemonTid,cast(shared)spawn(&_loggingDaemon));
}

enum LogLevel:ubyte{
	all,
	trace,
	info,
	warning,
	error,
	fatal,
	off
}
debug enum defaultLogLevel=LogLevel.trace;
else enum defaultLogLevel=LogLevel.info;

private shared LogLevel _globalogLevel=defaultLogLevel;
LogLevel globalogLevel(){return atomicLoad(_globalogLevel);}
void globalogLevel(LogLevel lv){atomicStore(_globalogLevel,lv);}

struct LogArgDefine{
	alias logLevel=AliasSeq!(LogLevel,AF.ct|AF.rt);
	alias errno=AliasSeq!(int,AF.ct|AF.rt|AF.i,.errno);
}

enum LogAPIMixin=q{
	import std.conv: text;
	import std.datetime: Clock;
	import std.concurrency: send,thisTid;
	import slibrary.logging.impl: loggingDaemon,LogEntry,SLogger,Logger;
	send(loggingDaemon,LogEntry(
			traceInfo,logLevel,errno,
			thisTid.text,Clock.currTime,text(args)));
};

struct LogEntry{
	immutable(TraceInfo)* traceInfo;
	LogLevel			  logLevel;
	int 				  errno;
	string				  threadIdText;
	SysTime				  timestamp;
	string 				  msg;
}

class Logger{
	this(LogLevel lv){_logLevel=lv;}
	final void logLevel(LogLevel lv){_logLevel=lv;}
	final LogLevel logLevel(){return _logLevel;}
	abstract void writelog(in LogEntry logEntry);
private:
	LogLevel _logLevel;
}
class SLogger: Logger{
	this(LogLevel lv){super(lv);}
	override void writelog(in LogEntry logEntry){
		import std.stdio: writeln;
		writeln(*logEntry.traceInfo);
		writeln(logEntry);
	}
private:
	import std.stdio: File;
	File[] files;
	bool stdout,stderr;
}

private void _loggingDaemon(){
	import std.stdio;
	Logger logger=new SLogger(LogLevel.min);
	scope (success){//Clean up
	}
	bool isRunning=true;
	while (isRunning)
		try receive(
			// Log
			(in LogEntry logEntry){logger.writelog(logEntry);},
			// Change loglevel
			(LogLevel logLevel){logger.logLevel=logLevel;},
			// Modify Logger
			(void function(Logger) modify){modify(logger);});
	catch (OwnerTerminated)
		isRunning=false;
}
