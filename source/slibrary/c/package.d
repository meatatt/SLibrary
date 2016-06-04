module slibrary.c;

import std.traits: isSomeChar;
import std.exception: assumeUnique;

@property inout(C)[] tempDString(C)(inout C* cstr) pure nothrow @nogc @trusted
if(isSomeChar!C){
	if (cstr is null) return null;
	import core.stdc.string: strlen;
	return cstr[0..cstr.strlen];
}

string strerror(int errno) @trusted{
	version (CRuntime_Glibc){
		import core.stdc.string: strerror_r;
		char[1024] buf=void;
		auto s = strerror_r(errno, buf.ptr, buf.length);
	}
	else{
		import core.stdc.string: c_strerror=strerror;
		auto s=c_strerror(errno);
	}
	return assumeUnique(s.tempDString);
}
