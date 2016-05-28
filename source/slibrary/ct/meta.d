module slibrary.ct.meta;

import std.meta: AliasSeq,templateNot,ApplyLeft,ApplyRight,Filter,anySatisfy;

import slibrary.ct.predicate: isSame;

alias None=AliasSeq!();

template toSymbols(alias symbol,names...) {
	static if (names.length>0)
		alias toSymbols=AliasSeq!(mixin("symbol."~names[0]),toSymbols!(symbol,names[1..$]));
	else
		alias None toSymbols;
}

template staticPipe(templates...){
	template staticPipeImpl(Args...){
		static if (templates.length>0){
			alias staticPipe!(templates[1..$]) _staticPipe;
			alias templates[0] template_;
			alias AliasSeq!(_staticPipe!(template_!Args)) staticPipeImpl;
		}
		else
			alias Args staticPipeImpl;
	}
	alias staticPipeImpl staticPipe;
}

alias templateNot!anySatisfy noneSatisfy;

template Exculde(BlackList...){
	private alias pred(alias Arg)=noneSatisfy!(ApplyLeft!(isSame,Arg),BlackList);
	alias from(Args...)=Filter!(pred,Args);
}

template extractName(Method...)if (Method.length==1){
	enum rawName=Method.stringof;
	static assert (rawName[0..6]=="tuple(");
	static assert (rawName[$-1]==')');
	enum extractName=rawName[6..$-1];
}
