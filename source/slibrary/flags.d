module slibrary.flags;

import slibrary.ct.meta: toSymbols;

E[] extractFlags(T,E=T)(T e)if (is(E==enum)){
	E[] r;
	foreach (m;toSymbols!(E,__traits(allMembers,E)))
		if (e&m)r~=m;
	return r;
}
