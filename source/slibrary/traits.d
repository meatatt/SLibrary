module slibrary.traits;

template isInheritable(T){
	import std.traits: isFinalClass;
	static if(is(T:Object)&&!isFinalClass!T)
		enum isInheritable=true;
	else
		enum isInheritable=false;
}