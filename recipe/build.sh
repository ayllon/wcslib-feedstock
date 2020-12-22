#! /bin/bash

IFS=$' \t\n' # workaround bad conda/toolchain interaction
set -e

if [[ $(uname) == Darwin ]] ; then
    export LDFLAGS="-Wl,-rpath,$PREFIX/lib $LDFLAGS"
else
    export LDFLAGS="-Wl,-rpath-link,$PREFIX/lib $LDFLAGS"
fi

configure_args=(
    --prefix=$PREFIX
    --enable-fortran
    --with-cfitsiolib=$PREFIX/lib
    --with-cfitsioinc=$PREFIX/include
    --with-pgplotlib=$PREFIX/lib
    --with-pgplotinc=$PREFIX/include/pgplot
    --host="${HOST}"
    --build="${BUILD}"
)

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
    configure_args=(${configure_args[@]} "--without-pgplot")
    autoreconf -if
fi

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* config/

./configure "${configure_args[@]}" || { cat config.log ; exit 1 ; }
make # note: Makefile is not parallel-safe
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
    make check
fi
mkdir -p $PREFIX/share/man/man1
make install

cd $PREFIX
rm -rf share/doc
rm include/wcslib # this is a symlink
mv include/wcslib-* include/wcslib
