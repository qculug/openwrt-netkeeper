# openwrt-netkeeper

The project is based on [miao1007/Openwrt-NetKeeper](https://github.com/miao1007/Openwrt-NetKeeper) .

## How to build

```
$ cd openwrt
$ git clone https://github.com/qculug/openwrt-netkeeper.git package/netkeeper
$ make menuconfig #choose Network -> netkeeper
$ make -j $(($(nproc) + 1)) V=s
```
