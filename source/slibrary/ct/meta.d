module slibrary.ct.meta;

import std.meta: Alias,AliasSeq,templateNot,Filter,anySatisfy;

import slibrary.ct.predicate: isSame,isFunction,isValue,isNonemptyTList,isNotLocal;

alias None=AliasSeq!();

alias toSymbols(alias env)=None;
template toSymbols(alias env,alias name,names...){
	static if (__traits(compiles,__traits(getMember,env,name))){
		alias symbol=Alias!(__traits(getMember,env,name));
		static if (isFunction!symbol)
			alias toSymbols=AliasSeq!(__traits(getOverloads,env,name),
				toSymbols!(env,names));
		else
			alias toSymbols=AliasSeq!(symbol,toSymbols!(env,names));
	}
	else{
		import slibrary.ct.log: Warning;
		mixin Warning!("Ignoring "~__traits(identifier,env)~"."~name);
		alias toSymbols=toSymbols!(env,names);
	}
}

template TypeOf(alias a)if (isValue!a){alias typeof(a) TypeOf;}

template staticPipe(Templates...){
	static if (isNonemptyTList!Templates){
		alias nextPipe=.staticPipe!(Templates[1..$]);
		alias Template=Templates[0];
		alias staticPipe(Args...)=nextPipe!(Template!Args);
	}
	else
		alias staticPipe(Args...)=SmartAlias!Args;
}

template staticCast(Templates...){
	template staticCast(Args...){
		static if (isNonemptyTList!Templates){
			alias nextCast=.staticCast!(Templates[1..$]);
			alias Template=Templates[0];
			alias staticCast=SmartAlias!(Template!Args,nextCast!Args);
		}
		else
			alias None staticCast;
	}
}

alias templateNot!anySatisfy noneSatisfy;

// std fix
unittest{
	template c(X1,X2){}
	alias ApplyLeft!(ApplyRight,c) cxx;
	alias cxx!int cxi;
	alias cxi!uint cui;
	static assert (isSame!(cui,c!(uint,int)));
}
template ApplyLeft(alias Template, args...){
	alias ApplyLeft(right...)=SmartAlias!(Template!(args,right));
}
// Ditto
template ApplyRight(alias Template, args...){
	alias ApplyRight(left...)=SmartAlias!(Template!(left,args));
}

template SmartAlias(a...){
	static if (a.length==1)
		alias SmartAlias=Alias!a;
	else
		alias SmartAlias=AliasSeq!a;
}
