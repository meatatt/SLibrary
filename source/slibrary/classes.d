module slibrary.classes;

import slibrary.traits: isInheritable;

import std.format: format;
import std.typecons:isTuple;
import std.meta: allSatisfy;

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
	}
	class Z{
		mixin multipleInheritance!(A,B,C);
		import std.typecons: tuple;
		this(){
			_super=new _Super(
				tuple(),
				tuple(1,2),
				3
				);
		}
		int iO(){return -1;}
	}
	auto z=new Z;
	assert (z.i==9);
	assert (z.iA==9);
	assert (z.iB==1);
	assert (z.iZ==2);
	assert (z.iC==3);
	assert (z.iO()==-1);
	I i=z;
	assert (i.vi()==z.iB);
	assert (z._super_2.i==z.iC);
	static assert (is(typeof(z._super_1)==B));
}
mixin template multipleInheritance(Super...)
if (Super.length>0&&allSatisfy!(isInheritable,Super)){
	alias multipleInheritanceImpl!(1,Super) _Super;
	protected _Super _super;
	//access N-super-class via _super_N
	alias Super[0] _Super_0;
	@property _Super_0 _super_0(){return _super;}
	//permit direct access from outside
	@property _Super _super_r(){return _super;}
	alias _super_r this;
}
template multipleInheritanceImpl(size_t Index,Super...){
	static assert (Super.length>0);
	class multipleInheritanceImpl: Super[0]{
		static if (Super.length>1){
			alias multipleInheritanceImpl!(Index+1,Super[1..$]) _Super;
			protected _Super _super;
			//access N-super-class via _super_N
			mixin (q{
					alias Super[1] _Super_%1$s;
					@property _Super_%1$s _super_%1$s(){return _super;}
				}.format(Index));
			@property _Super _super_r(){return _super;}
			alias _super_r this;
		}
		//ctor forwarding
		this(Params...)(Params params)
		if (Params.length==Super.length){
			static if (Super.length>1)
				_super=new _Super(params[1..$]);
			static if (isTuple!(Params[0]))
				super(params[0].expand);
			else
				super(params[0]);
		}
	}
}
