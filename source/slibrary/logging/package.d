module slibrary.logging;

import slibrary.logging.api: LogAPI;
import slibrary.logging.impl: defaultImpl;

public import slibrary.logging.impl: informDaemon,Logger,SLogger,globalogLevel;

mixin LogAPI!defaultImpl;
version (SLibraryVerboseUnittest) unittest{
	import std.stdio: stdout,stderr;
	// Initialize the Global Logger
	informDaemon((){
			SLogger sl=new SLogger(LogLevel.min);
			//sl.insertFile(stdout);
			sl.insertFile(stderr);
			//sl.colorizeStdOut();
			sl.colorizeStdErr();
			Logger l=sl;
			return l;
		});
	error!404("Errno can be specified.");
	warning("If it is NOT specified, errno will be auto inferred from getErrno().");
	globalogLevel=LogLevel.warning;
	warning("Current Global LogLevel is ",globalogLevel);
	trace("Trace Messages only would be logged while debugging");
	info("This Message would be ignored due to current globalogLevel");
	//Add log file to logger
	informDaemon("log.txt");
	fatal("This Message goes into file log.txt");
	globalogLevel=LogLevel.min;
	//Call it AGAIN to remove this file from logger
	informDaemon("log.txt");
	warning("Message would be auto generated from errno if not given.");
	info("So it is recommand to place an info() at the end of program:");
	info();
}
