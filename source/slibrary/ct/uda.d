module slibrary.ct.uda;

import std.format: format;
import std.traits: getUDAs;
import std.meta: Filter;

import slibrary.ct.predicate: isSame,isTListNotEmpty;
import slibrary.ct.meta: None,toSymbols,staticPipe,ApplyLeft,ApplyRight;

alias getMembersByUDA(alias symbol, alias attribute)
	=Filter!(
		staticPipe!(
					ApplyRight!(getUDAs,attribute),
					isTListNotEmpty),
		toSymbols!(symbol,__traits(allMembers,symbol)));
