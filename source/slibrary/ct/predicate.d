module slibrary.ct.predicate;

import std.meta: allSatisfy,
	anySatisfy,
	templateAnd,templateNot;
import std.traits: isFinalClass,
	BaseClassesTuple,InterfacesTuple,
	isSomeFunction,isFunctionPointer;

import slibrary.ct.meta: ApplyLeft;

enum isValue(v...)=v.length==1
	&&__traits(compiles,typeof(v[0]))
		&&!is(typeof(v[0])==void);

template isSame(v...)if (v.length==2){
	static if (allSatisfy!(isValue,v))
		enum isSame=v[0]==v[1];
	else
		enum isSame=__traits(isSame,v[0],v[1]);
}

enum isInheritable(alias T)=is(T:Object)&&!isFinalClass!T;

alias isInheritedFrom(alias this_,alias super_)
	=anySatisfy!(ApplyLeft!(isSame,super_),
		BaseClassesTuple!this_,
			InterfacesTuple!this_);

enum isMixinTemplate(mixinTemplate,Args)=__traits(compiles,
	{class X{mixin mixinTemplate!Args;}});

enum isFunction(alias f)=isSomeFunction!f&&!isFunctionPointer!f;

enum isEmptyTList(TList...)=TList.length==0;
enum isNonemptyTList(TList...)=TList.length>0;

template isNotLocal(alias S){
	template NonLocalTemplate(alias S){}
	enum isNotLocal=__traits(compiles,NonLocalTemplate!S);
}
