module slibrary.logging;

import slibrary.logging.api: LogAPI;
import slibrary.logging.impl: defaultImpl;

mixin LogAPI!defaultImpl;
version (SLibraryVerboseUnittest) unittest{
	error("Test");
}
