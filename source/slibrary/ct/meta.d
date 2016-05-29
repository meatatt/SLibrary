module slibrary.ct.meta;

import std.meta: Alias,AliasSeq,templateNot,Filter,anySatisfy;

import slibrary.ct.predicate: isSame,isFunction,isValue,isNonemptyTList,isNotLocal;

alias None=AliasSeq!();

template toSymbols(alias env,names...){
	static if (isNonemptyTList!names){
		static if (__traits(compiles,__traits(getMember,env,names[0]))){
			alias symbol=Alias!(__traits(getMember,env,names[0]));
			static if (isFunction!symbol)
				alias toSymbols=AliasSeq!(
					__traits(getOverloads,env,names[0]),
					toSymbols!(env,names[1..$]));
			else
				alias toSymbols=AliasSeq!(symbol,toSymbols!(env,names[1..$]));
		}
		else{
			import slibrary.ct.log: Warning;
			mixin Warning!("Ignoring "~__traits(identifier,env)~"."~names[0]);
			alias toSymbols=toSymbols!(env,names[1..$]);
		}
	}
	else
		alias None toSymbols;
}

template TypeOf(a...)if (a.length==1&&isValue!(a[0])){
	alias typeof(a[0]) TypeOf;
}

template staticPipe(Templates...){
	static if (isNonemptyTList!Templates){
		alias nextPipe=.staticPipe!(Templates[1..$]);
		alias Template=Templates[0];
		alias staticPipe(Args...)=nextPipe!(Template!Args);
	}
	else
		alias staticPipe(Args...)=Alias!Args;
}

template staticCast(Templates...){
	template staticCast(Args...){
		static if (isNonemptyTList!Templates){
			alias nextCast=.staticCast!(Templates[1..$]);
			alias Template=Templates[0];
			alias staticCast=AliasSeq!(Template!Args,nextCast!Args);
		}
		else
			alias None staticCast;
	}
}

alias templateNot!anySatisfy noneSatisfy;

// std fix
template ApplyLeft(alias Template, args...)
{
	static if (args.length)
	{
		template ApplyLeft(right...)
		{
			static if (is(typeof(typeof(Template!(args, right)))))
				enum ApplyLeft = Template!(args, right); // values
			else
				alias ApplyLeft = Template!(args, right); // symbols
		}
	}
	else
		alias ApplyLeft = Template;
}
// Ditto
template ApplyRight(alias Template, args...)
{
	static if (args.length)
	{
		template ApplyRight(left...)
		{
			static if (is(typeof(typeof(Template!(left, args)))))
				enum ApplyRight = Template!(left, args); // values
			else
				alias ApplyRight = Template!(left, args); // symbols
		}
	}
	else
		alias ApplyRight = Template;
}
