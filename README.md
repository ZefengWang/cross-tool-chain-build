# cross-tool-chain-build

This respository is for building cross tool chain.  
You can edit the shell script for your needs.  
Default buinding is for aarch64-linux-gnueabi.
## system requires
At least 12G free space harddisk on your system.
## usage
```shell
./compile.sh
```
## bugs
```c
/* Maximum length of any multibyte character in any locale.
   We define this value here since the gcc header does not define
   the correct value.  */
#define MB_LEN_MAX      16
```

## note
The gcc 9.2 has a bug when you build cross tool chain.  
In the gcc-9.2.0/libsanitizer/asan/asan_linux.cc , `PATH_MAX` was not declear, you need declear it.  
I search it in libc, it is 1024.

## option
The default is not compile gdbserver.  
If you want to compile gdbserver, you will need to edit the source code.  
After copy the src to the dir src, you need to find all the declear of macro `MB_LEN_MAX` and change them from `1` to `16`.  
```shell
cd ./src
grep -rn "#define MB_LEN_MAX" ./
```
And then, you need to find the src code change them.   
After that, you should edit the script and find the function `checkall` and `buildgdbserver`,   
remove the charactor  `#`.   
## tested
This script is verified on ubuntu 19.04
