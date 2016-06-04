module slibrary.logging.impl;

import core.stdc.errno: errno;
import core.atomic: atomicLoad,atomicStore;

import std.conv: text;
import std.stdio: File;
import std.uni: toUpper;
import std.meta: AliasSeq;
import std.ascii: newline;
import std.variant: Variant;
import std.exception: enforce;
import std.format: formattedWrite;
import std.array: Appender,appender;
import std.algorithm.iteration: each;
import std.string: chomp,lastIndexOf;
import std.datetime: SysTime,DateTime,Duration;
import std.algorithm.mutation: remove,SwapStrategy;
import std.concurrency: Tid,spawn,send,receive,receiveTimeout,OwnerTerminated;

import slibrary.c: strerror;
import slibrary.logging.api: AF=ArgFlags,TraceInfo;
import slibrary.colorize: ColorBaseType,FGColorBright,
	setFGColor,setFGColorStdErr,restore,restoreStdErr;
import slibrary.ct.tricks: EnumMap,dynamicEnumMap;

alias slibrary.logging.impl defaultImpl;

private shared Tid _daemonTid;
Tid loggingDaemon(){
	return atomicLoad(_daemonTid);
}
shared static this(){
	atomicStore(_daemonTid,cast(shared)spawn(&_loggingDaemon));
}
void informDaemon(T)(lazy T arg){
	loggingDaemon.send(arg);
}

debug enum defaultLogLevel=LogLevel.trace;
else enum defaultLogLevel=LogLevel.info;
enum LogLevel:ubyte{
	all,
	trace,
	info,
	warning,
	error,
	fatal,
	off
}

alias levelName=dynamicEnumMap!(LevelName,LogLevel);
alias LevelName=EnumMap!(LevelNameOf,LogLevel);
enum LevelNameOf(LogLevel lv)=lv.text.toUpper;

bool isLogActiveAt(LogLevel logLevel){
	if (logLevel==LogLevel.trace)
	{debug return true;else return false;}
	return logLevel>=globalogLevel;
}

private shared LogLevel _globalogLevel=defaultLogLevel;
LogLevel globalogLevel(){return atomicLoad(_globalogLevel);}
void globalogLevel(LogLevel lv){atomicStore(_globalogLevel,lv);}

struct LogArgDefine{
	alias logLevel=AliasSeq!(LogLevel,AF.ct|AF.rt);
	alias errno=AliasSeq!(int,AF.ct|AF.rt|AF.i,.errno);
	alias condition=AliasSeq!(bool,AF.ct|AF.rt|AF.i,true);
	alias msg=AliasSeq!(string,AF.ct|AF.i,genMsg,"errno","args");
}
string genMsg(Args...)(int errno,lazy Args args){
	static if (args.length==0)
		return errno.strerror;
	else
		return args.text;
}

enum LogAPIMixin=q{
	import std.conv: text;
	import std.datetime: Clock;
	import std.concurrency: send,thisTid;
	import slibrary.logging.impl: informDaemon,isLogActiveAt,LogEntry;

	if (condition&&isLogActiveAt(logLevel))
	informDaemon(LogEntry(
			&traceInfo,logLevel,errno,
			thisTid.text,Clock.currTime,msg));
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
	final bool isLogActiveAt(LogLevel logLevel_){return logLevel_>=_logLevel;}
	abstract void writelog(in LogEntry);
	void opCall(Variant var){
		if (var.type==typeid(LogLevel))
			_logLevel=var.get!LogLevel;
		else{
			import slibrary.logging: warning;
			warning("Ignored Event: ",var);
		}
	}
private:
	LogLevel _logLevel;
}
class SLogger: Logger{
	this(LogLevel lv){
		super(lv);
		lastTimeStamp=SysTime(DateTime.init);
	}
	void insertFile(string fn){files~=File(fn, "a");}
	void insertFile(File file){files~=file;}
	void removeFile(in char[] fn){
		files=files.remove!(file=>file.name==fn,SwapStrategy.unstable);
	}
	void removeFile(in File file){removeFile(file.fileno);}
	void removeFile(in int fileno){
		files=files.remove!(file=>file.fileno==fileno,SwapStrategy.unstable);
	}
	void removeAll(){files.length=0;}
	void colorizeStdErr(){_isColorizeStdErr=true;}
	void colorizeStdOut(){_isColorizeStdOut=true;}
	void plainStdErr(){_isColorizeStdErr=false;}
	void plainStdOut(){_isColorizeStdOut=false;}
	override void writelog(in LogEntry logEntry){with(logEntry){
			auto buf=appender!string;
			void flush(){
				files.each!(f=>f.lockingTextWriter.put(buf.data));
				buf=appender!string;
			}

			if (isDateMarkRequired(timestamp))
				buf.formattedWrite("---%04d-%02d-%02d---%s",
					timestamp.year, timestamp.month, timestamp.day,newline);
			buf.formattedWrite("%02d:%02d:%02d ",
				timestamp.hour, timestamp.minute, timestamp.second);
			flush();

			setColor(getColor(logEntry.logLevel));
			buf.put('['~levelName(logEntry.logLevel));
			if (errno!=0)
				buf.formattedWrite(" %d",errno);
			buf.put(']');
			flush();
			restoreColor();

			if (LogLevel.trace==logEntry.logLevel){
				ptrdiff_t fnIdx = traceInfo.file.lastIndexOf('/') + 1;
				ptrdiff_t funIdx = traceInfo.funcName.lastIndexOf('.') + 1;
				buf.formattedWrite(" %s(%u).%s:",traceInfo.moduleName,
					traceInfo.line,traceInfo.funcName[funIdx .. $]);
			}

			buf.put(' ');
			buf.put(msg.chomp);
			buf.put(newline);
			flush();
		}}
	override void opCall(Variant var) {
		if (var.type==typeid(string)){
			auto files_=files;
			removeFile(var.get!string);
			//If unchanged
			if (files.length==files_.length)
				insertFile(var.get!string);
		}
		else if (var.type==typeid(File)){
			auto files_=files;
			removeFile(var.get!File);
			//If unchanged
			if (files.length==files_.length)
				insertFile(var.get!File);
		}
		else super.opCall(var);
	}
private:
	File[] files;
	bool _isColorizeStdErr,_isColorizeStdOut;
	enum ColorSet: ColorBaseType{
		trace	=FGColorBright.Blue,
		info	=FGColorBright.Green,
		warning	=FGColorBright.Magenta,
		error	=FGColorBright.Red,
		fatal	=FGColorBright.Cyan
	}
	alias getColor=dynamicEnumMap!(ColorSet,LogLevel);
	void setColor(ColorBaseType fg){
		if (_isColorizeStdErr)
			setFGColorStdErr(fg);
		if (_isColorizeStdOut)
			setFGColor(fg);
	}
	void restoreColor(){
		if (_isColorizeStdErr)
			restoreStdErr();
		if (_isColorizeStdOut)
			restore();
	}
	SysTime lastTimeStamp;
	bool isDateMarkRequired(SysTime curr){
		if (curr.day==lastTimeStamp.day
			&& curr.month==lastTimeStamp.month
			&& curr.year==lastTimeStamp.year)
			return false;
		lastTimeStamp=curr;
		return true;
	}
}

private void _loggingDaemon(){
	Logger logger;
	bool isRunning=true;
	alias handlers=AliasSeq!(
		(LogEntry logEntry){
			enforce!Error(logger !is null,"Logger hasn't initialized!");
			logger.writelog(logEntry);
		},
		(Logger function() newLogger){
			logger=newLogger();
		},
		(OwnerTerminated o){
			isRunning=false;
		},
		(lazy Variant var){
			enforce!Error(logger !is null,"Logger hasn't initialized!");
			logger(var);
		});
	//Clean up rest Messages
	scope (success) while (receiveTimeout(Duration.zero,handlers)){}
	while (isRunning)
		receive(handlers);
}
