module slibrary.oo.inheritance;

import std.format: format;
import std.typecons: isTuple;
import std.traits: TemplateArgsOf,ReturnType,Parameters,functionAttributes;
import std.meta: anySatisfy,allSatisfy,AliasSeq,Filter,staticMap,templateOr;

import slibrary.ct.uda: getMembersByUDA,getUDAs;
import slibrary.ct.meta: staticPipe,TypeOf,ApplyLeft,ApplyRight;
import slibrary.ct.predicate: isSame,isInheritable,isInheritedFrom;

//Multiple Inheritance:
mixin template multipleInheritance(Super...)
if (Super.length>0&&allSatisfy!(isInheritable,Super)){
	//Re-import symbols because this is a mixin template
	import std.meta: anySatisfy,allSatisfy,templateOr;
	
	import slibrary.ct.meta: ApplyLeft,ApplyRight,staticPipe,staticCast;
	import slibrary.ct.predicate: isInheritable,isSame,isInheritedFrom;
	import slibrary.oo.inheritance: OverrideImpl,multipleInheritanceImpl;
	
	template Override(T...)if (allSatisfy!(
			staticPipe!(
				staticCast!(
					ApplyLeft!(ApplyRight,isSame),
					ApplyLeft!(ApplyRight,isInheritedFrom)),
				templateOr,
				ApplyRight!(anySatisfy,Super))
			,T)){enum Override=OverrideImpl!T();}
	
	alias multipleInheritanceImpl!(typeof(this),Super) _Super_;
	protected _Super_ _super_;
	@property T _super(T)()if (anySatisfy!(ApplyRight!(isSame,T),Super)){
		static if (is(T==Super[0]))
			return _super_;
		else
			return _super_._super!T;
	}
	//permit direct access from outside
	@property _Super_ _super_r(){return _super_;}
	alias _super_r this;
}
// - Usage:
unittest{
	enum a=1,b=2,c=3;
	interface I{int vi();}
	interface I_{int vi_();}
	static class A:I,I_{
		this(){i=iA=a;}
		int i,iA;
		override int vi(){return iA;}
		override int vi_(){return i;}
	}
	static class B:I{
		this(int i_,int i__){i=b;iB=i_;iZ=i__;}
		int i,iB,iZ;
		override int vi() {return iB;}
	}
	static class C:I_{
		this(int i_){i=c;iC=i_;}
		int i,iC;
		int iO(){return iC;}
		long iO(int i_){return i_;}
		override int vi_(){return i;}
	}
	class Z{
		mixin multipleInheritance!(A,B,C);
		int function() f;
		import std.typecons: tuple;
		this(){
			_super_=new _Super_(this,
				tuple(),
				tuple(10,20),
				30
				);
		}
		@Override!C int iO(){return -1;}//override C.iO
		//Can't override due to different attributes
		/+@Override!C+/ int iO(int o){return o+1;}
		//Same as @Override!(A,B)
		@Override!I int vi(){return 7;}
		//Same as @Override!I_
		@Override!(A,C) int vi_(){return 8;}
	}
	auto z=new Z;
	assert (z.i==z._super!A.i);
	assert (z.iA==a);
	assert (z.iB==10);
	assert (z.iZ==20);
	assert (z.iC==30);
	assert (z.iO()==z._super!C.iO());
	assert (z.vi()==z._super!A.vi());
	assert (z.vi()==z._super!B.vi());
	assert (z.vi_()==z._super!C.vi_());
	I i=z;
	assert (i.vi()==z.vi());
	assert (z._super!B.i==b);
	static assert (is(typeof(z._super!C)==C));
	C c_=z;
	assert (c_ is z._super!C);
	assert (c_.iO()==z.iO());
	assert (c_.iO(10)!=z.iO(10));
}
// - Impl:
static struct OverrideImpl(T...){}
template multipleInheritanceImpl(This,Super_t...){
	static assert (Super_t.length>0&&isInheritable!(Super_t[0]));

	static class multipleInheritanceImpl: Super_t[0]{
		static if (Super_t.length>1){
			alias multipleInheritanceImpl!(This,Super_t[1..$]) _Super_;
			protected _Super_ _super_;
			@property T _super(T)()
			if (anySatisfy!(ApplyRight!(isSame,T),Super_t)){
				static if (is(T==Super_t[1]))
					return _super_;
				else
					return _super_._super!T;
			}
			@property _Super_ _super_r(){return _super_;}
			alias _super_r this;
		}
		//Override Wrappers
		private This _this;
		alias overloads=Filter!(
			staticPipe!(
				//member => UDAs
				ApplyRight!(getUDAs,OverrideImpl),
				//UDAs => Types
				ApplyLeft!(staticMap,TypeOf),
				//OverrideImpl!T => T
				ApplyLeft!(staticMap,ApplyRight!(TemplateArgsOf,OverrideImpl)),
				//Is there any T
				ApplyLeft!(anySatisfy,templateOr!(
						// == Super ?
						ApplyRight!(isSame,Super_t[0]),
						// OR: is a base class/interface of Super?
						ApplyLeft!(isInheritedFrom,Super_t[0])))),
			getMembersByUDA!(This,OverrideImpl));
		mixin overrideImpl!overloads;
		mixin template overrideImpl(overloads_t...){
			static if (overloads_t.length>0){
				mixin(q{
						override @functionAttributes!(overloads_t[0])
							ReturnType!(overloads_t[0]) %1$s
								(Parameters!(overloads_t[0]) param)
						{return _this.%1$s(param);}
					}.format(__traits(identifier,overloads_t[0])));
				mixin overrideImpl!(overloads_t[1..$]);
			}
		}
		//ctor forwarding
		this(Params...)(This this_,Params params)
		if (Params.length==Super_t.length){
			_this=this_;
			static if (Super_t.length>1)
				_super_=new _Super_(this_,params[1..$]);
			static if (isTuple!(Params[0]))
				super(params[0].expand);
			else
				super(params[0]);
		}
	}
}
