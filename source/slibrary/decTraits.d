module slibrary.decTraits;

mixin template dec_extractName(){
	template extractName(Method...)if (Method.length==1){
		enum rawName=Method.stringof;
		static assert (rawName[0..6]=="tuple(");
		static assert (rawName[$-1]==')');
		enum extractName=rawName[6..$-1];
	}
}
mixin template dec_toSymbols(){
	import std.format: format;
	import std.meta: AliasSeq;

	template toSymbols(alias symbol,names...) {
		static if (names.length>0)
			mixin(q{alias toSymbols=AliasSeq!(symbol.%s,toSymbols!(symbol,names[1..$]));}
				.format(names[0]));
		else
			alias AliasSeq!() toSymbols;
	}
}
mixin template dec_getSymbolsByUDA(){
	// fix '.this' error in std.traits.getSymbolsByUDA,which can't parse an alias-this symbol
	template getSymbolsByUDA(alias symbol, alias attribute) {
		import std.format: format;
		import std.traits: hasUDA;
		import std.meta: AliasSeq,Filter;

		import slibrary.traits: Exculde;
		import slibrary.decTraits: dec_toSymbols;
		mixin dec_toSymbols!() decTS;

		enum hasSpecificUDA(string name)=mixin("hasUDA!(symbol.%s, attribute)".format(name));

		alias membersWithUDA = decTS.toSymbols!(symbol,Filter!(hasSpecificUDA,
				Exculde!"this".from!(__traits(allMembers,symbol))));
		
		// if the symbol itself has the UDA, tack it on to the front of the list
		static if (hasUDA!(symbol, attribute))
			alias getSymbolsByUDA = AliasSeq!(symbol, membersWithUDA);
		else
			alias getSymbolsByUDA = membersWithUDA;
	}
}