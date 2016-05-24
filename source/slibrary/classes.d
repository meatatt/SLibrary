module slibrary.classes;

import slibrary.traits: isInheritable,countUntil,canOverride,
	functionMatch,isRefFunction,getSymbolsByUDA,getName;

import std.format: format;
import std.typecons: isTuple;
import std.meta: allSatisfy,Filter,AliasSeq;
import std.traits: isNarrowString,ReturnType,Parameters,functionAttributes;

//Multiple Inheritance
unittest{
	static class A{
		this(){i=iA=9;}
		int i,iA;
	}
	interface I{int vi();}
	static class B:I{
		this(int i_,int i__){i=iB=i_;iZ=i__;}
		int i,iB,iZ;
		override int vi() {
			return iB;
		}
	}
	static class C{
		this(int i_){i=iC=i_;}
		int i,iC;
		int iO(){return iC;}
		ref int iO(int o){return *new int(o);}
	}
	class Z{
		mixin multipleInheritance!(A,B,C);
		import std.typecons: tuple;
		this(){
			_super_=new _Super(this,
				tuple(),
				tuple(1,2),
				3
				);
		}
		@Override!C int iO(){return -1;}//override C.iO
		//Error: static assert  "function Z.iO does not override any function"
		/+@Override!C+/ int iO(int o){return o+1;}
		@Override!B int vi(){return 7;}//override I.vi
	}
	auto z=new Z;
	assert (z.i==9);
	assert (z.iA==9);
	assert (z.iB==1);
	assert (z.iZ==2);
	assert (z.iC==3);
	assert (z.iO()==-1);
	I i=z;
	assert (i.vi()==z.vi());
	assert (z._super!B.i==z.iB);
	static assert (is(typeof(z._super!C)==C));
	C c=z;
	assert (c is z._super!C);
	assert (c.iO()==z.iO());
	assert (c.iO(10)!=z.iO(10));
}
struct Override(T)if (isInheritable!T){}
mixin template multipleInheritance(Super...)
if (Super.length>0&&allSatisfy!(isInheritable,Super)){
	alias multipleInheritanceImpl!(typeof(this),Super) _Super;
	protected _Super _super_;
	@property T _super(T)(){
		static if (is(T==Super[0]))
			return _super_;
		else
			return _super_._super!T;
	}
	//permit direct access from outside
	@property _Super _super_r(){return _super_;}
	alias _super_r this;
}
template multipleInheritanceImpl(This,Super...){
	static assert (Super.length>0&&isInheritable!(Super[0]));
	class multipleInheritanceImpl: Super[0]{
		static if (Super.length>1){
			alias multipleInheritanceImpl!(This,Super[1..$]) _Super;
			protected _Super _super_;
			@property T _super(T)(){
				static if (is(T==Super[1]))
					return _super_;
				else
					return _super_._super!T;
			}
			@property _Super _super_r(){return _super_;}
			alias _super_r this;
		}
		//override Impl
		private This _this;
		alias AliasSeq!(getSymbolsByUDA!(This,Override!(Super[0]))) thisOverrides;
		template getAllOverloads(thisOverrides_t...){
			import std.traits: hasUDA;
			template markedAsOverride(alias overload){
				enum markedAsOverride=hasUDA!(overload,Override!(Super[0]));
			}
			static if (thisOverrides_t.length>0){
				alias AliasSeq!(
					Filter!(markedAsOverride,
						__traits(getOverloads,This,getName!(thisOverrides_t[0]))),
					getAllOverloads!(thisOverrides_t[1..$])) getAllOverloads;
			}
			else
				alias AliasSeq!() getAllOverloads;
		}
		alias getAllOverloads!thisOverrides thisOverloads;
		static if (thisOverloads.length>0)
			mixin thisMatch!thisOverloads;
		mixin template thisMatch(thisOverloads_t...){
			alias AliasSeq!(__traits(getVirtualMethods,Super[0],getName!(thisOverloads_t[0])))
				superOverloads;
			mixin (q{
					mixin superMatch!superOverloads superMatch_%1$s;
					static assert (is(typeof(this.superMatch_%1$s.%2$s)),
						"function "
						~This.stringof~'.'~getName!(thisOverloads_t[0])
						~" does not override any function");
				}.format(thisOverloads_t.length,getName!(thisOverloads_t[0])));
			mixin template superMatch(superOverloads_t...){
				static if (functionMatch!(thisOverloads_t[0],superOverloads_t[0]))
					mixin(q{
							override @functionAttributes!(superOverloads_t[0])
								ReturnType!(superOverloads_t[0]) %1$s
									(Parameters!(superOverloads_t[0]) param)
							{return _this.%1$s(param);}
						}.format(getName!(thisOverloads_t[0])));
				static if (superOverloads_t.length>1)
					mixin superMatch!(superOverloads_t[1..$]);
			}
			static if (thisOverloads_t.length>1)
				mixin thisMatch!(thisOverloads_t[1..$]);
		}
		//ctor forwarding
		this(Params...)(This this_,Params params)
		if (Params.length==Super.length){
			_this=this_;
			static if (Super.length>1)
				_super_=new _Super(this_,params[1..$]);
			static if (isTuple!(Params[0]))
				super(params[0].expand);
			else
				super(params[0]);
		}
	}
}
