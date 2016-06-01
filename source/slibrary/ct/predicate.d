module slibrary.ct.predicate;

import std.meta: Filter,allSatisfy,anySatisfy;
import std.traits: isFinalClass,BaseClassesTuple,InterfacesTuple;

import slibrary.flags: extractFlags;
import slibrary.ct.meta: ApplyLeft,ApplyRight,toTList,staticPipe;

enum isValue(v...)=v.length==1&&getCategory!v&Category.Value;

enum isTList(v...)=v.length!=1&&getCategory!v&Category.Tuple;

template isSame(v...)if (v.length==2){
	static if (allSatisfy!(isValue,v))
		enum isSame=v[0]==v[1];
	else
		enum isSame=__traits(isSame,v[0],v[1]);
}

enum isInheritable(T)=is(T:Object)&&!isFinalClass!T;

alias isInheritedFrom(this_,super_)
	=anySatisfy!(ApplyLeft!(isSame,super_),
		BaseClassesTuple!this_,
		InterfacesTuple!this_);

enum isMixinTemplate(alias mixinTemplate,Args...)=__traits(compiles,
	{class X{mixin mixinTemplate!Args;}});

enum isFunction(alias f)=getCategory!f&Category.Function;

enum isEmptyTList(TList...)=TList.length==0;
enum isNonemptyTList(TList...)=TList.length>0;

enum isNotLocal(alias S)=!(getCategory!(S)&Category.Local);

enum getCategory(A...)=parseCategory!A();
enum Category:uint{
	NONE			=0,
	
	Tuple			=1<<0,
	//Including Literal Values, Enums and Immutable Variables
	Literal			=1<<1,
	Symbol			=1<<2,
	Type			=1<<3,
	//Local ones can't be used in NonLocal Templates
	Local			=1<<4,
	Value			=1<<5,
	Template		=1<<6,
	Function		=1<<7
}
// Tests:
unittest{with(Category){
		static assert (extractFlags(getCategory!())==[Tuple]);
		enum e=0;
		static assert (extractFlags(getCategory!e)==[Literal,Value]);
		enum E;
		static assert (extractFlags(getCategory!E)==[Symbol,Type]);
		static assert (extractFlags(getCategory!(void,int))==[Tuple,Type]);
		void f(){}
		static assert (extractFlags(getCategory!f)==[Symbol,Local,Function]);
		int i;
		static assert (extractFlags(getCategory!i)==[Symbol,Local,Value]);
		static assert (extractFlags(getCategory!(f,i))==[Tuple,Symbol,Local]);
		static int si;
		static assert (extractFlags(getCategory!si)==[Symbol,Value]);
		template t(){}
		static assert (extractFlags(getCategory!t)==[Symbol,Template]);
	}}
// - Impl:
private static Category parseCategory(A...)()
out(res){assert (res!=Category.NONE);}
body{if (__ctfe)with(Category){
		auto res=NONE;
		static if (A.length!=1){
			res|=Tuple;
			static if (A.length>1)
				foreach (c;scanTuple!A)
					res|=c;
		}
		else{
			static if (__traits(compiles,{enum x=A[0];}))
				res|=Literal|Value;
			else{
				static if (is(typeof(identifer!A)))
					res|=Symbol;
				static if (is(typeof(A[0]) T)){
					static if (is(T==void))
						res|=Template;
					else static if (is(T==function)||is(T==delegate))
						res|=Function;
					else
						res|=Value;
				}
				else{
					static assert (is(A[0]));
					res|=Type;
				}
			}
		}
		template NonLocalTemplate(S...){}
		static if (!__traits(compiles,NonLocalTemplate!A))
			res|=Local;
		return res;
	}assert(0);}
private enum identifer(A...)=__traits(identifier,A[0]);
private template scanTuple(A...){
	alias toTList!(extractFlags(getCategory!(A[0]))) cs;
	static if (A.length>1)
		alias scanTuple=Filter!(
			staticPipe!(
				ApplyLeft!(ApplyLeft,isSame),
				ApplyRight!(anySatisfy,cs)),
			scanTuple!(A[1..$]));
	else
		alias cs scanTuple;
}
