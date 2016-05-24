module slibrary.traits;

import std.traits: isFinalClass;
import std.meta: allSatisfy,anySatisfy,Filter;

// Mixin ALL mixin templates
import slibrary.decTraits;
mixin dec_toSymbols!();
mixin mixinTemplates!(
	Filter!(isMixinTemplateVia!().at,
		toSymbols!(slibrary.decTraits,
			Exculde!"object".from!(__traits(allMembers,slibrary.decTraits)))));

template isInheritable(alias T){
	static if(is(T:Object)&&!isFinalClass!T)
		enum isInheritable=true;
	else
		enum isInheritable=false;
}
template Exculde(BlackList...){
	enum pred(alias Arg)=!anySatisfy!(isSame!Arg,BlackList);
	template from(Args...){
		alias Filter!(pred,Args) from;
	}
}
template isSame(alias A){
	template isSame(alias B){
		static if (is(typeof(A==B)))
			enum isSame=A==B;
		else
			enum isSame=__traits(isSame,A,B);
	}
}
template isMixinTemplateVia(Args...){
	template at(alias mT){
		static if (__traits(compiles,(){class T{mixin mT!Args;}}))
			enum at=true;
		else
			enum at=false;
	}
}
template mixinTemplates(mTs...)if (allSatisfy!(isMixinTemplateVia!().at,mTs)){
		mixin mixinTemplate!mTs;
		mixin template mixinTemplate(mTs_t...){
			static if (mTs_t.length>0){
				alias mTs_t[0] mT;
				mixin mT!();
				mixin mixinTemplate!(mTs_t[1..$]);
			}
		}
}
