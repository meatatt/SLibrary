module slibrary.logging.api;

enum ArgFlags:uint{
	ct=1<<0,
	rt=1<<1,
	i =1<<2
}

struct TraceInfo{
	int    line;
	string file;
	string funcName;
	string prettyFuncName;
	string moduleName;
}

mixin template LogAPI(alias Impl){
	alias LogLevel=Impl.LogLevel;
	alias LogArgDefine=Impl.LogArgDefine;
	alias LogAPIMixin=Impl.LogAPIMixin;

	import std.format: format;
	import std.meta: Filter,Alias,staticIndexOf,staticMap;

	import slibrary.logging.api: ArgFlags,TraceInfo;
	import slibrary.ct.meta: toSymbols,ApplyLeft,TypeOf;
	import slibrary.ct.predicate: isNonemptyTList,isFunction;

	template log(CTArgs...){
		void log(
			int    line			 =__LINE__,
			string file			 =__FILE__,
			string funcName		 =__FUNCTION__,
			string prettyFuncName=__PRETTY_FUNCTION__,
			string moduleName	 =__MODULE__,
			_Args...)(_Args _args){
			auto traceInfo=new immutable TraceInfo(
				line,file,funcName,prettyFuncName,moduleName);
			mixin parseCTArgs!([],__traits(allMembers,LogArgDefine));
			mixin (LogAPIMixin);
		}
	}
	mixin perLevelMethod!(__traits(allMembers,Impl.LogLevel));
private:
	mixin template perLevelMethod(string levelName,levelNames...){
		mixin(q{alias %1$s=ApplyLeft!(log,toSymbols!(LogLevel,levelName));}
			.format(levelName));
		static if (isNonemptyTList!levelNames)
			mixin perLevelMethod!levelNames;
	}
	mixin template parseCTArgs(string[] namesOfNotFoundArgs){
		static assert (CTArgs.length==
			__traits(allMembers,LogArgDefine).length-namesOfNotFoundArgs.length,
			"Unexpected Compile Time Args");
		mixin parseRTArgs!(0,0,namesOfNotFoundArgs);
	}
	mixin template parseCTArgs(string[] notFound,string name,names...){
		alias _cur=toSymbols!(LogArgDefine,name);
		alias _Index=staticIndexOf!(_cur[0],staticMap!(TypeOf,CTArgs));
		static if (_Index==-1){
			static assert (_cur[1]!=ArgFlags.ct,
				name~" must be passed at compile time");
			mixin parseCTArgs!(notFound~name,names);
		}
		else{
			static assert (_cur[1]&ArgFlags.ct,
				name~" shouldn't be passed at compile time");
			mixin (q{alias %1$s=Alias!(CTArgs[%2$s]);}.format(name,_Index));
			mixin parseCTArgs!(notFound,names);
		}
	}
	mixin template parseRTArgs(size_t Index,string[] names){
		alias args=_args[Index..$];
		mixin autoInitArgs!names;
	}
	mixin template parseRTArgs(size_t Index,size_t nIndex,string[] names){
		static if (Index==_Args.length||nIndex==names.length)
			mixin parseRTArgs!(Index,names);
		else{
			alias _cur=toSymbols!(LogArgDefine,names[nIndex]);
			static if (is(_cur[0]==_Args[Index])){
				static if (_cur[1]&ArgFlags.rt){
					mixin (q{alias %1$s=_args[%2$s];}
						.format(names[nIndex],Index));
					mixin parseRTArgs!(Index+1,0,
						names[0..nIndex]~names[nIndex+1..$]);
				}
				else//End
					mixin parseRTArgs!(Index,names);
			}
			else
				mixin parseRTArgs!(Index,nIndex+1,names);
		}
	}
	mixin template autoInitArgs(string[] names){
		static if (names.length>0){
			alias _cur=toSymbols!(LogArgDefine,names[0]);
			static assert (_cur[1]&ArgFlags.i,
				"Unknow Arg: "~_cur[0].stringof~" "~names[0]);
			static if (isFunction!(_cur[2]))
				mixin (q{auto %1$s=_cur[2]();}.format(names[0]));
			else
				mixin (q{alias %1$s=Alias!(_cur[2]);}.format(names[0]));
			mixin autoInitArgs!(names[1..$]);
		}
	}
}
