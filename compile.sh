#!/bin/bash

PROJ=`pwd`
BUILD="$PROJ/build"
SRC="$PROJ/src"
PACKAGE="$PROJ/package"
TARGET=aarch64-rockchip-linux-gnueabi 
INSTALL="$PROJ/$TARGET"

bin=binutils-2.33.1
glibc=glibc-2.29
gcc=gcc-9.2.0
gdb=gdb-8.3
linux=linux-5.3.7
gmp=gmp-6.1.2
mpfr=mpfr-3.1.4
mpc=mpc-1.1.0
isl=isl-0.18
gdbs=gdbserver

mt=-j`cat /proc/cpuinfo| grep "processor"| wc -l`

export PATH="$INSTALL/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LD_LIBRARY_PATH=

function checkdir() { if [ ! -d $1 ];then mkdir $1;fi }
function install_tools()
{
	sudo apt install libtool gawk texinfo gcc wget automake tar gzip autoconf gettext autogen guile-2.2 flex bison libncurses5-dev libncurses5 || exit 1;
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
	sed -i "77a #ifndef PATH_MAX\n#define PATH_MAX 1024\n#endif\n" $SRC/$gcc/libsanitizer/asan/asan_linux.cc || exit 1;
	ls $SRC/$gcc/mpc > /dev/null 2>&1	|| (tar xvzf $mpc.tar.gz -C $SRC/$gcc/	&& mv $SRC/$gcc/$mpc $SRC/$gcc/mpc) || exit 1;
	ls $SRC/$gcc/mpfr > /dev/null 2>&1	|| (tar xvzf $mpfr.tar.gz -C $SRC/$gcc/	&& mv $SRC/$gcc/$mpfr $SRC/$gcc/mpfr) || exit 1;
	ls $SRC/$gcc/gmp > /dev/null 2>&1	|| (tar xvJf $gmp.tar.xz -C $SRC/$gcc/	&& mv $SRC/$gcc/$gmp $SRC/$gcc/gmp) || exit 1;
	ls $SRC/$gcc/isl > /dev/null 2>&1	|| (tar xvjf $isl.tar.bz2 -C $SRC/$gcc/	&& mv $SRC/$gcc/$isl $SRC/$gcc/isl) || exit 1;
}

function check_all()
{
	checkdir $BUILD;checkdir $INSTALL;checkdir $PACKAGE; download;checkdir $SRC; decompress;
	checkdir $BUILD/$bin; checkdir $BUILD/$glibc;checkdir $BUILD/$gcc;
	checkdir $BUILD/$gdb; #checkdir $BUILD/$gdbs; checkdir $PROJ/$gdbs;
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

	make clean $mt || exit 1;
	make $mt || exit 1;
	make install $mt || exit 1;
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

	make clean  $mt || exit 1;
	make all-gcc  $mt || exit 1;
	make all-target-libgcc $mt || exit 1;
	make install-gcc $mt || exit 1;
	make install-target-libgcc $mt || exit 1;

}

function build_linux_header()
{
	cd $SRC/$linux
	make ARCH=arm64 CROSS_COMPILE=$TARGET-gcc INSTALL_HDR_PATH=$INSTALL/$TARGET headers_install $mt || exit 1
}

function build_gdb()
{
	cd $BUILD/$gdb
	rm ./* -rf
	../../src/$gdb/configure \
		--prefix=$INSTALL \
		--target=$TARGET

	make clean $mt || exit 1;
	make $mt || exit 1;
	make install $mt || exit 1;
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

	make clean $mt || exit 1;
	make $mt || exit 1;
	make install $mt || exit 1;
}

function build_gcc_with_glibc()
{
	cd $BUILD/$gcc
	rm ./* -rf
	../../src/$gcc/configure \
		--prefix=$INSTALL \
		--target=$TARGET \
		--enable-shared

	make clean $mt || exit 1;
	make $mt || exit 1;
	make install $mt || exit 1;
}

function build_gdbserver()
{
	cd $BUILD/$gdbs
	CXX=$TARGET-g++ CC=$TARGET-gcc ../../src/$gdb/gdb/$gdbs/configure --target=$TARGET --host=$TARGET --prefix=$PROJ/$gdbs --program-prefix=
	make clean $mt || exit 1;
	make $mt || exit 1;
	make install $mt || exit 1;
}

function build()
{	
	rm $INSTALL/* -rf
	build_binutils
	build_linux_header
	build_gcc_without_libc
	build_gdb
	build_glibc
	build_gcc_with_glibc
#	build_gdbserver
}

install_tools
check_all
build

ls $PROJ/program > /dev/null 2>&1 || mkdir $PROJ/program ;
cd $PROJ/program || exit 1;
echo -e "#include <stdio.h>\nint main()\n{\n\tprintf(\"hello world\\\n\");\n\treturn 0;\n}\n" > hello.c
$TARGET-gcc hello.c -o hello-$TARGET || echo "build demo failed!" && exit 1;
