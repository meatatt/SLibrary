module slibrary.ct.tricks;

import std.format: format;
import std.meta: AliasSeq;

import slibrary.ct.meta: toSymbols,SmartAlias;

struct MemberMap(Type,alias Template){
	alias opDispatch(string name)=SmartAlias!(Template!(
			__traits(getMember,Type,name)));
}

template dynamicEnumMap(alias Template,Enum)if (is(Enum==enum)){
	auto dynamicEnumMap(Enum e){
		final switch (e) mixin (gencode());
	}
	string gencode(){if (__ctfe){string res;
			foreach (name;__traits(allMembers,Enum))res~=q{
				case Enum.%1$s: return Template!(Enum.%1$s);
			}.format(name);
			return res;}assert(0);}
}
