module slibrary.traits;

import std.traits: isFinalClass,isFinalFunction,ReturnType,Parameters,isCallable,
	functionAttributes,FunctionAttribute,hasUDA;
import std.meta: AliasSeq,allSatisfy,Filter;
import std.string : format;

template isInheritable(alias T){
	static if(is(T:Object)&&!isFinalClass!T)
		enum isInheritable=true;
	else
		enum isInheritable=false;
}
template countUntil(alias pred,T...){
	static if (T.length==0||pred!(T[0]))
		alias AliasSeq!() countUntil;
	else
		alias AliasSeq!(T[0],countUntil!(pred,T[1..$])) countUntil;
}
template canOverride(T,alias M){
	enum canOverride=__traits(isVirtualMethod,M)&&!isFinalFunction!M;
}
template functionMatch(func...)if (func.length==2&&allSatisfy!(isCallable,func)){
	enum functionMatch=is(ReturnType!(func[0])==ReturnType!(func[1]))
		&&is(Parameters!(func[0])==Parameters!(func[1]))
			&&functionAttributes!(func[0])==functionAttributes!(func[1]);
}
template isRefFunction(func...)if (func.length==1&&isCallable!func){
	enum isRefFunction=functionAttributes!func&FunctionAttribute.ref_;
}
// fix '.this' error in std.traits.getSymbolsByUDA,which can't parse an alias-this symbol
template getSymbolsByUDA(alias symbol, alias attribute) {
	// translate a list of strings into symbols. mixing in the entire alias
	// avoids trying to access the symbol, which could cause a privacy violation
	template toSymbols(names...) {
		static if (names.length == 1)
			mixin("alias toSymbols = AliasSeq!(symbol.%s);".format(names[0]));
		else static if (names.length>1)
			mixin("alias toSymbols = AliasSeq!(symbol.%s, toSymbols!(names[1..$]));"
				.format(names[0]));
		else
			alias AliasSeq!() toSymbols;
	}
	
	enum hasSpecificUDA(string name) = mixin("hasUDA!(symbol.%s, attribute)".format(name));

	alias membersWithUDA = toSymbols!(Filter!(hasSpecificUDA, excludeThis!(__traits(allMembers, symbol))));
	
	// if the symbol itself has the UDA, tack it on to the front of the list
	static if (hasUDA!(symbol, attribute))
		alias getSymbolsByUDA = AliasSeq!(symbol, membersWithUDA);
	else
		alias getSymbolsByUDA = membersWithUDA;
}
template getName(Method...)if (Method.length==1){
	enum rawName=Method.stringof;
	static assert (rawName[0..6]=="tuple(");
	static assert (rawName[$-1]==')');
	enum getName=rawName[6..$-1];
}
template stringToSymbols(alias symbol,names...) {
	static if (names.length == 1)
		mixin("alias toSymbols = AliasSeq!(symbol.%s);".format(names[0]));
	else
		mixin("alias toSymbols = AliasSeq!(symbol.%s, toSymbols!(names[1..$]));"
			.format(names[0]));
}
template excludeThis(names...){
	enum NotThis(string name)=name!="this";
	alias Filter!(NotThis,names) excludeThis;
}