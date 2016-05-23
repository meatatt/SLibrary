module slibrary.traits;

import std.traits: isFinalClass;

template isInheritable(T){
	static if(is(T:Object)&&!isFinalClass!T)
		enum isInheritable=true;
	else
		enum isInheritable=false;
}