module slibrary.logging.impl;

import std.meta: AliasSeq;

import slibrary.logging.api: AF=ArgFlags;
import slibrary.ct.predicate: isSame;
import slibrary.ct.meta: ApplyLeft;

alias slibrary.logging.impl defaultImpl;

enum LogLevel:ubyte{
	trace,
	info,
	warning,
	error,
	fatal
}

extern(C) int getErrno();

struct LogArgDefine{
	alias lv=AliasSeq!(LogLevel,AF.ct|AF.rt);
	alias errno=AliasSeq!(int,AF.ct|AF.rt|AF.i,getErrno);
}
