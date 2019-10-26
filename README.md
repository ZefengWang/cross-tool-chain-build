# cross-tool-chain-build

this respository is for building cross tool chain

You can edit the shell script for your needs

default buinding is for aarch64-linux-gnueabi

## system requires
at least 12G free space on your harddisk 

## usage

```shell
./compile.sh
```
## note

The gcc 9.2 has a bug when you build cross tool chain.  
In the gcc-9.2.0/libsanitizer/asan/asan_linux.cc , `PATH_MAX` was not declear, you need declear it.  
I search it in libc, it is 1024.

## This script is verified on ubuntu 19.04
