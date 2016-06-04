module slibrary.colorize;

import std.stdio: stderr,stdout;

import slibrary.ct.tricks: MemberMap;
import slibrary.ct.meta: staticSelect,staticFunction,Pred,ApplyLeft;

alias FGColorBright=MemberMap!(FGColor,staticFunction!Bright);
alias BGColorBright=MemberMap!(BGColor,staticFunction!Bright);

alias setFGColor=ApplyLeft!(setColor,false);
alias setBGColor=ApplyLeft!(setColor,true);
alias setFGColorStdErr=setFGColor!true;
alias setBGColorStdErr=setBGColor!true;
alias restoreStdErr=restore!true;

private alias output=staticSelect!(Pred,stderr,stdout);

version (SLibraryVerboseUnittest) unittest{
	import std.stdio: write,writeln;
	import std.ascii: newline;
	import slibrary.ct.meta: toSymbols;
	writeln(__MODULE__,':');
	foreach (c;toSymbols!(FGColor,__traits(allMembers,FGColor))){
		setFGColor(c);
		write(c);
		setFGColor(c.Bright);
		write("Bright",c);
	}
	restore();
	write(newline);
	foreach (c;toSymbols!(BGColor,__traits(allMembers,BGColor))){
		setBGColorStdErr(c);
		stderr.write(c);
		setBGColorStdErr(c.Bright);
		stderr.write("Bright",c);
	}
	restoreStdErr();
	stderr.write(newline);
}
version (Posix){
	import std.conv: text;

	alias ColorBaseType=ubyte;
	alias FGColor=Color;
	alias BGColor=Color;
	static assert (Color.max+0x08<=ColorBaseType.max);
	ColorBaseType Bright(Color color){return cast(ColorBaseType)(0x08+color);}
	void setColor(bool isBG=false,bool isStderr=false)(ColorBaseType color){
		output!isStderr.lockingTextWriter
			.put(prefix!isBG~color.text~suffix);
	}
	void restore(bool isStderr=false)(){
		output!isStderr.lockingTextWriter.put(_restore);
	}
private:
	enum Color: ColorBaseType{Black=0,Red,Green,Yellow,Blue,Magenta,Cyan,White}
	alias prefix=staticSelect!(Pred,bgPrefix,fgPrefix);
	enum _prefix="\x1b[",suffix="m",_restore=_prefix~'0'~suffix,
		fgPrefix=_prefix~"38;5;",bgPrefix=_prefix~"48;5;";
}
version (Windows){
	import core.sys.windows.wincon: CONSOLE_SCREEN_BUFFER_INFO,
		FOREGROUND_INTENSITY,FOREGROUND_BLUE,FOREGROUND_GREEN,FOREGROUND_RED,
		BACKGROUND_INTENSITY,BACKGROUND_BLUE,BACKGROUND_GREEN,BACKGROUND_RED,
		GetConsoleScreenBufferInfo,SetConsoleTextAttribute;
	import core.sys.windows.winbase: GetStdHandle,STD_OUTPUT_HANDLE,STD_ERROR_HANDLE;
	import core.atomic: atomicStore,atomicLoad;

	public import core.sys.windows.wincon: ColorBaseType=WORD;
	ColorBaseType Bright(FGColor color){return color|FOREGROUND_INTENSITY;}
	ColorBaseType Bright(BGColor color){return color|BACKGROUND_INTENSITY;}
	enum FGColor: ColorBaseType{
		Black=0,
		Red=FOREGROUND_RED,
		Green=FOREGROUND_GREEN,
		Blue=FOREGROUND_BLUE,
		Yellow=Red|Green,
		Cyan=Green|Blue,
		Magenta=Red|Blue,
		White=Red|Green|Blue
	}
	enum BGColor: ColorBaseType{
		Black=0,
		Red=BACKGROUND_RED,
		Green=BACKGROUND_GREEN,
		Blue=BACKGROUND_BLUE,
		Yellow=Red|Green,
		Cyan=Green|Blue,
		Magenta=Red|Blue,
		White=Red|Green|Blue
	}
	void setColor(bool isBG=false,bool isStderr=false)(ColorBaseType color){
		output!isStderr.flush();
		auto hConsole=GetStdHandle(handle!isStderr);
		CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
		GetConsoleScreenBufferInfo(hConsole,&consoleInfo);
		SetConsoleTextAttribute(hConsole,color|
			//Keep FG|BG Color
			(consoleInfo.wAttributes&mask!isBG));
	}
	void restore(bool isStderr=false)(){
		output!isStderr.flush();
		SetConsoleTextAttribute(
			GetStdHandle(handle!isStderr),
			atomicLoad(initial!isStderr));
	}
private:
	shared ColorBaseType cStderr,cStdout;
	shared static this(){
		CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
		GetConsoleScreenBufferInfo(GetStdHandle(STD_ERROR_HANDLE),&consoleInfo);
		atomicStore(cStderr,consoleInfo.wAttributes);
		GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),&consoleInfo);
		atomicStore(cStdout,consoleInfo.wAttributes);
	}
	alias initial=staticSelect!(Pred,cStderr,cStdout);
	alias handle=staticSelect!(Pred,STD_ERROR_HANDLE,STD_OUTPUT_HANDLE);
	alias mask=staticSelect!(Pred,bgMask,fgMask);
	enum fgMask=0xFFFF^(FOREGROUND_INTENSITY|FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE),
		bgMask=0xFFFF^(BACKGROUND_INTENSITY|BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE);
}
