module slibrary.ct.uda;

import std.meta: Filter;

import slibrary.ct.predicate: isNonemptyTList,isNotLocal;
import slibrary.ct.meta: toSymbols,staticPipe,ApplyRight;

alias getMembersByUDA(alias symbol,alias attribute)
	=Filter!(
		staticPipe!(
			ApplyRight!(getUDAs,attribute),
			isNonemptyTList),
		//Remove local symbols
		// which are not accessable from non-global templates
		Filter!(isNotLocal,
			toSymbols!(symbol,__traits(allMembers,symbol))));

static if (__traits(compiles,{import std.traits: getUDAs;}))
	public import std.traits: getUDAs;
else
template getUDAs(alias symbol, alias attribute){
	import std.traits: isInstanceOf;
	template isDesiredUDA(alias S) {
		static if(__traits(compiles, is(typeof(S) == attribute))) {
			enum isDesiredUDA = is(typeof(S) == attribute);
		} else {
			enum isDesiredUDA = isInstanceOf!(attribute, typeof(S));
		}
	}
	alias getUDAs = Filter!(isDesiredUDA, __traits(getAttributes, symbol));
}
