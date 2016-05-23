module slibrary.classes;

unittest{
	static class A{
		this(int i_){i=iA=i_;}
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
	}
	class Z{
		mixin multipleInheritance!(A,B,C);
		import std.typecons: tuple;
		this(){
			_super=new _Super(
				0,
				tuple(1,2),
				3
				);
		}
	}
	auto z=new Z;
	assert (z.i==0);
	assert (z.iA==0);
	assert (z.iB==1);
	assert (z.iZ==2);
	assert (z.iC==3);
	I i=z;
	assert (i.vi()==z.iB);
}
import slibrary.traits: isInheritable;
import std.meta: allSatisfy;
mixin template multipleInheritance(Super...)
if (Super.length>0&&allSatisfy!(isInheritable,Super)){
	alias multipleInheritanceImpl!(1,Super) _Super;
	private _Super _super;
	//access N-super-class via _super_N
	alias _Super _Super_0;
	alias _super _super_0;
	//permit direct access from outside
	@property _Super _super_r(){return _super;}
	alias _super_r this;
}
import std.typecons:isTuple;
template multipleInheritanceImpl(size_t Index,Super...){
	static assert (Super.length>0);
	class multipleInheritanceImpl: Super[0]{
		static if (Super.length>1){
			alias multipleInheritanceImpl!(Index+1,Super[1..$]) _Super;
			private _Super _super;
			//access N-super-class via _super_N
			import std.conv: to;
			mixin (q{alias _Super _Super_}~Index.to!string~";");
			mixin (q{alias _super _super_}~Index.to!string~";");
			//permit direct access from outside
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
