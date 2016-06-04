module slibrary.ct.tricks;

import std.format: format;

/** Creates a NEW enum type,
 * every member of which is created
 * by applying Template to the same name member under E
*/
template EnumMap(alias Template,E)if (is(E==enum)){
	mixin (gencode());
	string gencode(){if (__ctfe){string res;
			foreach (name;__traits(allMembers,E))res~=q{
				%1$s=Template!(E.%1$s),
			}.format(name);return q{
				enum EnumMap{%s}
			}.format(res);}assert(0);}
}

/** Creates a function returning a member of T
 * which has the same name to the input E
*/
template dynamicEnumMap(T,E)if (is(E==enum)&&is(T==enum)){
	T dynamicEnumMap(E e){
		final switch (e) mixin (gencode());
	}
	string gencode(){if (__ctfe){string res;
			foreach (name;__traits(allMembers,E))
				static if (__traits(hasMember,T,name))res~=q{
				case E.%1$s: return T.%1$s;}.format(name);else res~=q{
				case E.%1$s: assert(0);}.format(name);
			return res;}assert(0);}
}
