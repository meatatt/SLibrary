module slibrary.logging;

import slibrary.logging.api: LogAPI;
import slibrary.logging.impl: defaultImpl;

public import slibrary.logging.impl: informDaemon,Logger,SLogger,globalogLevel;

mixin LogAPI!defaultImpl;
version (SLibraryVerboseUnittest) unittest{
	import std.stdio: stdout,stderr;
	informDaemon((){
			SLogger l=new SLogger(LogLevel.min);
			//l.insertFile(stdout);
			l.insertFile(stderr);
			//l.colorizeStdOut();
			l.colorizeStdErr();
			return cast(Logger)l;
		});
	error(-1,"Errno can be specified.");
	warning("If it is NOT specified, errno will be auto inferred from getErrno().");
	globalogLevel=LogLevel.warning;
	trace("Trace Msgs are only logged while debugging");
	info("");
	informDaemon("log.txt");
	fatal("This Msg is written into file log.txt");
	globalogLevel=LogLevel.min;
	//TODO: Find a way to call removeFile()
	info("So it is recommand that call info() at the end of a program.");
	info();
}
