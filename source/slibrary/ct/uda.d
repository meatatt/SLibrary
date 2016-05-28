module slibrary.ct.uda;

import std.format: format;
import std.traits: getUDAs;
import std.meta: AliasSeq,Filter;

import slibrary.ct.meta: toSymbols,Exculde;

template getMembersByUDA(alias symbol, alias attribute) {
	enum hasSpecificUDA(string name)=
		mixin(q{getUDAs!(symbol.%1$s, attribute)}.format(name)).length>0;
	alias getMembersByUDA=toSymbols!(symbol,Filter!(hasSpecificUDA,
			Exculde!"this".from!(__traits(allMembers,symbol))));
}
