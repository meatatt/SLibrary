module slibrary.ct.meta;

import std.traits: isArray;
import std.meta: Alias,AliasSeq,templateNot,Filter,anySatisfy;

import slibrary.ct.predicate: isSame,isFunction,isValue,isTList,
	isNonemptyTList,isNotLocal;

alias None=AliasSeq!();

alias toSymbols(alias env)=None;
template toSymbols(alias env,alias name,names...){
	static if (__traits(compiles,__traits(getMember,env,name))){
		alias symbol=SmartAlias!(__traits(getMember,env,name));
		static if (!isTList!symbol&&isFunction!symbol)
			alias toSymbols=SmartAlias!(__traits(getOverloads,env,name),
				toSymbols!(env,names));
		else
			alias toSymbols=SmartAlias!(symbol,toSymbols!(env,names));
	}
	else{
		import slibrary.ct.log: Warning;
		mixin Warning!("Ignoring "~__traits(identifier,env)~"."~name);
		alias toSymbols=toSymbols!(env,names);
	}
}

template TypeOf(alias a)if (isValue!a){alias typeof(a) TypeOf;}

enum Pred(bool boolean)=boolean;

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

template staticSelect(alias pred,alias True,alias False){
	template staticSelect(Args...){
		static if (pred!Args)
			alias staticSelect=True;
		else
			alias staticSelect=False;
	}
}

template staticFunction(alias func){
	enum staticFunction(args...)=func(args);
}

deprecated
alias staticFind(alias pred,Args...)=staticFindImpl!(0,pred,Args);
private enum staticFindImpl(size_t Index,alias pred)=-1;
private template staticFindImpl(size_t Index,alias pred,alias Arg,Args...){
	static if (pred!Arg)
		enum staticFindImpl=Index;
	else
		alias staticFindImpl=staticFindImpl!(Index+1,pred,Args);
}

template toTList(alias ar)if (isArray!(typeof(ar))){
	static if (ar.length>0)
		alias toTList=AliasSeq!(ar[0],toTList!(ar[1..$]));
	else
		alias None toTList;
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
