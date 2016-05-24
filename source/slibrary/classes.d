module slibrary.classes;

//import slibrary.traits: isInheritable,functionMatch;


//Multiple Inheritance:
//	Usage:
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
		//Can't override due to different attributes
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
//	Impl:
import std.meta: allSatisfy;
import slibrary.traits: isInheritable;
struct Override(T)if (isInheritable!T){}
mixin template multipleInheritance(Super...)
if (Super.length>0&&allSatisfy!(isInheritable,Super)){
	import slibrary.traits: isInheritable;

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

	template multipleInheritanceImpl(This,Super_t...){
		static assert (Super_t.length>0&&isInheritable!(Super_t[0]));
		class multipleInheritanceImpl: Super_t[0]{
			static if (Super_t.length>1){
				alias multipleInheritanceImpl!(This,Super_t[1..$]) _Super;
				protected _Super _super_;
				@property T _super(T)(){
					static if (is(T==Super_t[1]))
						return _super_;
					else
						return _super_._super!T;
				}
				@property _Super _super_r(){return _super_;}
				alias _super_r this;
			}
			//Override Wrappers
			private This _this;
			import slibrary.decTraits: dec_extractName,dec_getSymbolsByUDA;
			mixin dec_extractName!();
			mixin dec_getSymbolsByUDA!();
			import std.meta: AliasSeq,Filter;
			import std.traits: hasUDA,ReturnType,Parameters,functionAttributes;
			alias AliasSeq!(getSymbolsByUDA!(This,Override!(Super_t[0]))) overrides;
			template getOverloads(overrides_t...){
				template hasMark(alias overload){
					enum hasMark=hasUDA!(overload,Override!(Super_t[0]));
				}
				static if (overrides_t.length>0){
					alias AliasSeq!(
						Filter!(hasMark,
							__traits(getOverloads,This,extractName!(overrides_t[0]))),
						getOverloads!(overrides_t[1..$])) getOverloads;
				}
				else
					alias AliasSeq!() getOverloads;
			}
			alias getOverloads!overrides overloads;
			static if (overloads.length>0)
				mixin overrideImpl!overloads;
			mixin template overrideImpl(overloads_t...){
				import std.format: format;
				mixin(q{
						override @functionAttributes!(overloads_t[0])
							ReturnType!(overloads_t[0]) %1$s
								(Parameters!(overloads_t[0]) param)
						{return _this.%1$s(param);}
					}.format(extractName!(overloads_t[0])));
				static if (overloads_t.length>1)
					mixin overrideImpl!(overloads_t[1..$]);
			}
			//ctor forwarding
			this(Params...)(This this_,Params params)
			if (Params.length==Super_t.length){
				_this=this_;
				static if (Super_t.length>1)
					_super_=new _Super(this_,params[1..$]);
				import std.typecons: isTuple;
				static if (isTuple!(Params[0]))
					super(params[0].expand);
				else
					super(params[0]);
			}
		}
	}
}
