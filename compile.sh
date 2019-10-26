#!/bin/bash

PROJ=`pwd`
BUILD="$PROJ/build"
SRC="$PROJ/src"
INSTALL="$PROJ/install"
PACKAGE="$PROJ/package"
TARGET=aarch64-rockchip-linux-gnueabi 

bin=binutils-2.33.1
glibc=glibc-2.29
gcc=gcc-9.2.0
gdb=gdb-8.3
linux=linux-5.3.7
gmp=gmp-6.1.2
mpfr=mpfr-3.1.4
mpc=mpc-1.1.0
isl=isl-0.18
export PATH="$INSTALL/bin:$PATH"
export LD_LIBRARY_PATH=

function checkdir() { if [ ! -d $1 ];then mkdir $1;fi }
function install_tools()
{
	sudo apt install libtool gwak texinfo gcc wget automake tar gzip autoconf gettext autogen guile flex bison bz2 || exit 1;
}

function download()
{
	cd $PACKAGE;
	ls $linux.tar.gz > /dev/null 2>&1	|| wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v5.x/$linux.tar.gz	|| exit 1;
	ls $gcc.tar.gz > /dev/null 2>&1		|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gcc/$gcc/$gcc.tar.gz	|| exit 1;
	ls $gdb.tar.gz > /dev/null 2>&1		|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/$gdb.tar.gz	|| exit 1;
	ls $bin.tar.gz > /dev/null 2>&1		|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/binutils/$bin.tar.gz	|| exit 1;
	ls $glibc.tar.gz > /dev/null 2>&1 	|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/glibc/$glibc.tar.gz	|| exit 1;
	ls $gmp.tar.xz > /dev/null  2>&1    	|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gmp/$gmp.tar.xz	|| exit 1;
	ls $mpfr.tar.gz > /dev/null 2>&1	|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/mpfr/$mpfr.tar.gz	|| exit 1;
	ls $mpc.tar.gz > /dev/null  2>&1    	|| wget https://mirrors.tuna.tsinghua.edu.cn/gnu/mpc/$mpc.tar.gz	|| exit 1;
	ls $isl.tar.bz2 > /dev/null 2>&1	|| wget https://gcc.gnu.org/pub/gcc/infrastructure/$isl.tar.bz2		|| exit 1;
}

function decompress()
{
	cd  $PACKAGE;
	ls $SRC/$linux > /dev/null 2>&1		|| tar xvzf $linux.tar.gz -C $SRC/ 		|| exit 1;
	ls $SRC/$bin > /dev/null 2>&1		|| tar xvzf $bin.tar.gz -C $SRC/		|| exit 1;
	ls $SRC/$gcc > /dev/null 2>&1		|| tar xvzf $gcc.tar.gz -C $SRC/		|| exit 1;
	ls $SRC/$gdb > /dev/null 2>&1		|| tar xvzf $gdb.tar.gz -C $SRC/		|| exit 1;
	ls $SRC/$glibc > /dev/null 2>&1		|| tar xvzf $glibc.tar.gz -C $SRC/		|| exit 1;
	ls $SRC/$gcc/mpc > /dev/null 2>&1	|| tar xvzf $mpc.tar.gz -C $SRC/$gcc/mpc	|| exit 1;
	ls $SRC/$gcc/mpfr > /dev/null 2>&1	|| tar xvzf $mpfr.tar.gz -C $SRC/$gcc/mpfr	|| exit 1;
	ls $SRC/$gcc/gmp > /dev/null 2>&1	|| tar xvJf $gmp.tar.xz -C $SRC/$gcc/gmp	|| exit 1;
}

function check_all()
{
	checkdir $BUILD;checkdir $INSTALL;checkdir $PACKAGE; download;checkdir $SRC; decompress;
	checkdir $BUILD/$bin; checkdir $BUILD/$glibc;checkdir $BUILD $gcc;
	checkdir $BUILD/$gdb; checkdir $BUILD/$linux;
}

function build_binutils()
{
	echo "$CC"
	cd $BUILD/$bin
	rm ./* -rf
	../../src/$bin/configure \
		--prefix=$INSTALL \
		--target=$TARGET \
		--disable-shared 

	make clean || exit 1;
	make -j12 || exit 1;
	make install || exit 1;
}

function build_gcc_without_libc()
{
	cd $BUILD/$gcc
	rm ./* -rf
	../../src/$gcc/configure \
		--prefix=$INSTALL \
		--target=$TARGET \
		--without-headers \
		--disable-multilib \
		--disable-threads \
		--disable-shared 

	make clean  -j12 || exit 1;
	make all-gcc  -j12 || exit 1;
	make all-target-libgcc -j12 || exit 1;
	make install-gcc -j12 || exit 1;
	make install-target-libgcc -j12 || exit 1;

}

function build_linux_header()
{
	cd $SRC/$linux
	make ARCH=arm64 CROSS_COMPILE=$TARGET INSTALL_HDR_PATH=$INSTALL/$TARGET headers_install || exit 1
}

function build_gdb()
{
	cd $BUILD/$gdb
	rm ./* -rf
	../../src/$gdb/configure \
		--prefix=$INSTALL \
		--target=$TARGET

	make -j12 || exit 1;
	make install ;
}

function build_glibc()
{
	cd $BUILD/$glibc
	rm ./* -rf
	CC=$TARGET-gcc AR=$TARGET-ar RANLIB=$TARGET-ranlib ../../src/$glibc/configure \
		--prefix=$INSTALL/$TARGET \
		--host=$TARGET \
		--target=$TARGET \
		--with-headers=$INSTALL/$TARGET/include

	make -j12 || exit 1;
	make install || exit 1;
}

function build_gcc_with_glibc()
{
	cd $BUILD/$gcc
	rm ./* -rf
	../../src/$gcc/configure \
		--prefix=$INSTALL \
		--target=$TARGET \
		--enable-shared

	make -j12 || exit 1;
	make install || exit 1;
}

function build()
{
	build_binutils
	build_linux_header
	build_gcc_without_libc
	build_gdb
	build_glibc
	build_gcc_with_glibc
}

check_all
#build

cd $PROJ/program || exit 1;
echo -e "#include <stdio.h>\nint main()\n{\n\tprintf(\"hello world\\\n\");\n\treturn 0;\n}\n" > hello.c
$INSTALL/bin/$TARGET-gcc hello.c -o hello-aarch64 || echo "build demo failed!" && exit 1;
