# Zig version of `sha1sum` coreutil

**To build from source code you must have `zig` binary available on your system**

## Installation

```
git clone https://github.com/Hershell-A-Makowitzky/Crescenc.git/tree/zig-version
```
```
cd Crescenc
```
```
zig build
```

## Run

```
pushd zig-out/bin && echo "Hello World" | ./hersha - && popd
```
Expected output:

```
0a4d55a8d778e5022fab701977c5d840bbc486d0  -
```

For further usage please check `https://www.man7.org/linux/man-pages/man1/sha1sum.1.html` 
