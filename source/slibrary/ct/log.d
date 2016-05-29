﻿module slibrary.ct.log;

mixin template Warning(string msg,
	int line=__LINE__,string file=__FILE__,string moduleName=__MODULE__){
	version (unittest)
		pragma (msg,file~"("~line.stringof~"): "~msg);
}
