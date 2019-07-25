#!/bin/sh

OUTFILE="profiler_library_flags.sexp"
if [ "Linux" = "`uname -s`" ]; then
	echo "(-ldw)" > ${OUTFILE}
else
	echo "()" > ${OUTFILE}
fi
