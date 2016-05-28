﻿module slibrary.ct.predicate;

import std.meta: allSatisfy;
import std.traits: isFinalClass;

template isValue(v...)if (v.length==1){
	enum isValue=__traits(compiles,typeof(v[0]));
}

template isSame(v...)if (v.length==2){
	static if (allSatisfy!(isValue,v))
		enum isSame=v[0]==v[1];
	else
		enum isSame=__traits(isSame,v[0],v[1]);
}

enum isInheritable(alias T)=is(T:Object)&&!isFinalClass!T;

enum isMixinTemplate(mixinTemplate,Args)=__traits(compiles,
	{class X{mixin mixinTemplate!Args;}});

public import std.traits: isFunction=isSomeFunction;
/+
template isFunction(f...)if (f.length==1){
	static if (is(typeof(& T[0]) U : U*) && is(U == function) || is(typeof(& T[0]) U == delegate)){
		enum isFunction=true;
		pragma (msg,"get");
	}
	else
		enum isFunction=false;
}+/