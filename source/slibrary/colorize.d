module slibrary.colorize;

version (SLibraryVerbose) unittest{
	import std.stdio: write;
	import std.ascii: newline;
	import slibrary.ct.meta: toSymbols;
	foreach (c;toSymbols!(FGColor,__traits(allMembers,FGColor))){
		setFGColor(c);
		write(c);
		setFGColor(c.Bright);
		write("Bright",c);
	}
	restore();
	foreach (c;toSymbols!(BGColor,__traits(allMembers,BGColor))){
		setBGColor(c);
		write(c);
		setBGColor(c.Bright);
		write("Bright",c);
	}
	restore();
	write("Normal",newline);
}
import std.stdio: stderr,stdout;
version (Posix){
	import std.conv: text;
	alias FGColor=Color;
	alias BGColor=Color;
	private enum Color:ubyte{Black=0,Red,Green,Yellow,Blue,Magenta,Cyan,White}
	private enum prefix="\x1b[",tail="m",
		fgPrefix=prefix~"38;5;",bgPrefix=prefix~"48;5;",_restore=prefix~'0'~tail;
	ubyte Bright(ubyte color){return cast(ubyte)(0x08+color);}
	void setFGColor(ubyte color,bool isStderr=false){
		(isStderr?stderr:stdout).lockingTextWriter
			.put(fgPrefix~color.text~tail);
	}
	void setBGColor(ubyte color,bool isStderr=false){
		(isStderr?stderr:stdout).lockingTextWriter
			.put(bgPrefix~color.text~tail);
	}
	void restore(bool isStderr=false){
		(isStderr?stderr:stdout).lockingTextWriter.put(_restore);
	}
}
version (Windows){
	import core.sys.windows.wincon: WORD,CONSOLE_SCREEN_BUFFER_INFO,
		FOREGROUND_INTENSITY,FOREGROUND_BLUE,FOREGROUND_GREEN,FOREGROUND_RED,
		BACKGROUND_INTENSITY,BACKGROUND_BLUE,BACKGROUND_GREEN,BACKGROUND_RED,
		GetConsoleScreenBufferInfo,SetConsoleTextAttribute;
	import core.sys.windows.winbase: GetStdHandle,STD_OUTPUT_HANDLE,STD_ERROR_HANDLE;
	import core.atomic: atomicStore,atomicLoad;
	private shared WORD cStderr,cStdout;
	shared static this(){
		CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
		GetConsoleScreenBufferInfo(GetStdHandle(STD_ERROR_HANDLE),&consoleInfo);
		atomicStore(cStderr,consoleInfo.wAttributes);
		GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),&consoleInfo);
		atomicStore(cStdout,consoleInfo.wAttributes);
	}
	WORD Bright(FGColor color){return color|FOREGROUND_INTENSITY;}
	WORD Bright(BGColor color){return color|BACKGROUND_INTENSITY;}
	enum FGColor: WORD{
		Black=0,
		Red=FOREGROUND_RED,
		Green=FOREGROUND_GREEN,
		Blue=FOREGROUND_BLUE,
		Yellow=Red|Green,
		Cyan=Green|Blue,
		Magenta=Red|Blue,
		White=Red|Green|Blue
	}
	enum BGColor: WORD{
		Black=0,
		Red=BACKGROUND_RED,
		Green=BACKGROUND_GREEN,
		Blue=BACKGROUND_BLUE,
		Yellow=Red|Green,
		Cyan=Green|Blue,
		Magenta=Red|Blue,
		White=Red|Green|Blue
	}
	private enum FGMask=0xFFFF^(FOREGROUND_INTENSITY|FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE),
		BGMask=0xFFFF^(BACKGROUND_INTENSITY|BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE);
	void setFGColor(WORD color,bool isStderr=false){
		if (isStderr)stderr.flush();else stdout.flush();
		auto handle=GetStdHandle(isStderr?STD_ERROR_HANDLE:STD_OUTPUT_HANDLE);
		CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
		GetConsoleScreenBufferInfo(handle,&consoleInfo);
		SetConsoleTextAttribute(handle,color|
			//Keep Background Color
			(consoleInfo.wAttributes&FGMask));
	}
	void setBGColor(WORD color,bool isStderr=false){
		if (isStderr)stderr.flush();else stdout.flush();
		auto handle=GetStdHandle(isStderr?STD_ERROR_HANDLE:STD_OUTPUT_HANDLE);
		CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
		GetConsoleScreenBufferInfo(handle,&consoleInfo);
		SetConsoleTextAttribute(handle,color|
			//Keep Foreground Color
			(consoleInfo.wAttributes&BGMask));
	}
	void restore(bool isStderr=false){
		if (isStderr)stderr.flush();else stdout.flush();
		SetConsoleTextAttribute(
			GetStdHandle(isStderr?STD_ERROR_HANDLE:STD_OUTPUT_HANDLE),
			atomicLoad(isStderr?cStderr:cStdout));
	}
}
