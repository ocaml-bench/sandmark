prefix="$1"
os="$2"
if [ -e configure.ac ]; then
    exec ./configure ${OCAMLCONFIGOPTION} --prefix "$prefix" --with-default-string=unsafe
else
    unsafe_string=''
    if grep -q 'default_safe_string=true' configure; then
	unsafe_string='-no-force-safe-string -default-unsafe-string'
    fi
    case "$os" in
	macos|freebsd|openbsd)
	    exec ./configure ${OCAMLCONFIGOPTION} -prefix "$prefix" $unsafe_string -cc cc -aspp "cc -c";;
	*)
	    exec ./configure ${OCAMLCONFIGOPTION} -prefix "$prefix" $unsafe_string;;
    esac
fi
