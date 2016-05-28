module slibrary.oo.inheritance;

//Multiple Inheritance:
// - Usage:
unittest{
	interface I{int vi();}
	static class A:I{
		this(){i=iA=9;}
		int i,iA;
		override int vi(){return iA;}
	}
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
			_super_=new _Super_(this,
				tuple(),
				tuple(1,2),
				3
				);
		}
		@Override!C int iO(){return -1;}//override C.iO
		//Can't override due to different attributes
		/+@Override!C+/ int iO(int o){return o+1;}
		//Same as @Override!(A,B)
		@Override!I int vi(){return 7;}//override I.vi
	}
	auto z=new Z;
	assert (z.i==9);
	assert (z.iA==9);
	assert (z.iB==1);
	assert (z.iZ==2);
	assert (z.iC==3);
	assert (z.iO()==-1);
	assert (z.vi()==z._super!A.vi());
	assert (z.vi()==z._super!B.vi());
	I i=z;
	assert (i.vi()==z.vi());
	assert (z._super!B.i==z.iB);
	static assert (is(typeof(z._super!C)==C));
	C c=z;
	assert (c is z._super!C);
	assert (c.iO()==z.iO());
	assert (c.iO(10)!=z.iO(10));
}
// - Impl:
static struct OverrideImpl(T...){}
import std.meta: allSatisfy;
import slibrary.ct.predicate: isInheritable;
mixin template multipleInheritance(Super...)
if (Super.length>0&&allSatisfy!(isInheritable,Super)){
	//Re-import because this is a mixin template
	import std.meta: anySatisfy,templateOr;

	import slibrary.ct.meta: ApplyLeft,ApplyRight,staticPipe,staticCast;
	import slibrary.ct.predicate: isInheritable,isSame,isInheritance;
	import slibrary.oo.inheritance: OverrideImpl;

	template Override(T...)if (allSatisfy!(
			staticPipe!(
				staticCast!(
					ApplyLeft!(ApplyRight,isSame),
					ApplyLeft!(ApplyRight,isInheritance)),
				templateOr,
				ApplyRight!(anySatisfy,Super)),T)){
		enum Override=OverrideImpl!T();
	}

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

	template multipleInheritanceImpl(This,Super_t...){
		import std.format: format;
		import std.meta: AliasSeq,Filter,staticMap,templateOr;
		import std.traits: getUDAs,TemplateArgsOf,
			ReturnType,Parameters,functionAttributes;

		import slibrary.ct.uda: getMembersByUDA;
		import slibrary.ct.meta: staticPipe,TypeOf,extractName,ApplyLeft;
		import slibrary.ct.predicate: isInheritance;

		static assert (Super_t.length>0&&isInheritable!(Super_t[0]));
		static class multipleInheritanceImpl: Super_t[0]{
			static if (Super_t.length>1){
				alias multipleInheritanceImpl!(This,Super_t[1..$]) _Super_;
				protected _Super_ _super_;
				@property T _super(T)()
				if (anySatisfy!(ApplyRight!(isSame,T),Super)){
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
							ApplyLeft!(isInheritance,Super_t[0])))),
				getMembersByUDA!(This,OverrideImpl));
			mixin overrideImpl!overloads;
			mixin template overrideImpl(overloads_t...){
				static if (overloads_t.length>0){
					mixin(q{
							override @functionAttributes!(overloads_t[0])
								ReturnType!(overloads_t[0]) %1$s
									(Parameters!(overloads_t[0]) param)
							{return _this.%1$s(param);}
						}.format(extractName!(overloads_t[0])));
					mixin overrideImpl!(overloads_t[1..$]);
				}
			}
			//ctor forwarding
			this(Params...)(This this_,Params params)
			if (Params.length==Super_t.length){
				_this=this_;
				static if (Super_t.length>1)
					_super_=new _Super_(this_,params[1..$]);
				import std.typecons: isTuple;
				static if (isTuple!(Params[0]))
					super(params[0].expand);
				else
					super(params[0]);
			}
		}
	}
}
