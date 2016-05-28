module slibrary.ct.meta;

import std.meta: Alias,AliasSeq,templateNot,Filter,anySatisfy;

import slibrary.ct.predicate: isSame,isFunction,isValue;

alias None=AliasSeq!();

template toSymbols(alias env,names...) {
	static if (names.length>0){
		static if (__traits(compiles,mixin("env."~names[0]))){
			alias symbol=AliasSeq!(mixin("env."~names[0]));
			static if (isFunction!symbol)
				alias toSymbols=AliasSeq!(__traits(getOverloads,env,names[0]),
					toSymbols!(env,names[1..$]));
			else
				alias toSymbols=AliasSeq!(symbol,toSymbols!(env,names[1..$]));
		}
		else
			alias toSymbols=toSymbols!(env,names[1..$]);
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

template staticCast(Templates...){
	template staticCast(Args...){
		static if (Templates.length>0){
			alias nextCast=.staticCast!(Templates[1..$]);
			alias Template=Templates[0];
			alias staticCast=AliasSeq!(Template!Args,nextCast!Args);
		}
		else
			alias None staticCast;
	}
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