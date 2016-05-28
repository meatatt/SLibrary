module slibrary.ct.meta;

import std.meta: Alias,AliasSeq,templateNot,ApplyLeft,ApplyRight,Filter,anySatisfy;

import slibrary.ct.predicate: isSame,isFunction,isValue;

alias None=AliasSeq!();

template toSymbols(alias env,names...) {
	static if (names.length>0){
		alias symbol=AliasSeq!(mixin("env."~names[0]));
		static if (isFunction!symbol)
			alias toSymbols=AliasSeq!(__traits(getOverloads,env,names[0]),toSymbols!(env,names[1..$]));
		else
			alias toSymbols=AliasSeq!(symbol,toSymbols!(env,names[1..$]));
	}
	else
		alias None toSymbols;
}

template TypeOf(a...)if (a.length==1&&isValue!(a[0])){
	alias typeof(a[0]) TypeOf;
}

template staticPipe(Templates...){
	static if (Templates.length>0)
	template staticPipe(Args...){
		alias nextPipe=.staticPipe!(Templates[1..$]);
		alias Template=Templates[0];
		alias nextArgs=Template!Args;
		alias staticPipe=nextPipe!nextArgs;
	}
	else
		alias staticPipe(Args...)=Alias!Args;
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
