# netkeeper-openwrt

The project is based on [miao1007/Openwrt-NetKeeper](https://github.com/miao1007/Openwrt-NetKeeper).

## How to build

```
$ cd openwrt/package
$ git clone https://github.com/qculug/netkeeper-openwrt.git
$ make menuconfig #choose Network -> netkeeper
$ make -j $(($(nproc) + 1)) V=s
```
