# 1. 准备工具

## 1.1. 下载 QEMU

https://qemu.weilnetz.de/w64/

添加环境变量

![image](assets/image.png)

## 1.2. 下载固件

https://releases.linaro.org/components/kernel/uefi-linaro/16.02/release/qemu64/

中的 QEMU_EFI.fd

## 1.3. 虚拟网卡工具

https://build.openvpn.net/downloads/releases/tap-windows-9.24.7-I601-Win10.exe

## 1.4. Kylin 操作系统

银河麒麟服务器操作系统 V10 SP3 x86_64 版 2403（兆芯/海光）

https://iso.kylinos.cn/web_pungi/download/cdn/9D2GPNhvxfsF3BpmRbJjlKu0dowkAc4i/Kylin-Server-V10-SP3-2403-Release-20240426-x86_64.iso

```shell
magnet:?xt=urn:btih:GVSUMKN3Y4AWHI6S7HNERCQY27N4FPGY&dn=Kylin-Server-V10-SP3-2403-Release-20240426-x86_64.iso&tr=http%3A%2F%2Fwx.kylinos.cn%3A46969%2Fannounce&tr=udp%3A%2F%2Fwx.kylinos.cn%3A46969%2Fannounce&xl=4696293376
```

银河麒麟服务器操作系统 V10 SP3 aarch64 版 2403（飞腾/鲲鹏）

https://iso.kylinos.cn/web_pungi/download/cdn/ni3tIfZoEKLDglszRXvh9WymuwOT5r6M/Kylin-Server-V10-SP3-2403-Release-20240426-arm64.iso

```shell
magnet:?xt=urn:btih:MFT4Y6HFZU2GIRH44I2CHZWUIOKHQ23M&dn=Kylin-Server-V10-SP3-General-Release-2303-ARM64.iso&tr=http%3A%2F%2Fwx.kylinos.cn%3A46969%2Fannounce&tr=udp%3A%2F%2Fwx.kylinos.cn%3A46969%2Fannounce&xl=4415842304
```

银河麒麟服务器操作系统 V10 SP3_loongarch64 版 2403（龙芯3B5000）

https://iso.kylinos.cn/web_pungi/download/cdn/tLh71VaxXSoTDP8yBz4YnrMZlmk3QvGJ/Kylin-Server-V10-SP3-2403-Release-20240426-loongarch64.iso

```shell
magnet:?xt=urn:btih:6L4AERU7B3JWFO7O5Q5HM5IAVJTQ6PZP&dn=Kylin-Server-V10-SP3-2403-Release-20240426-loongarch64.iso&tr=http%3A%2F%2Fwx.kylinos.cn%3A46969%2Fannounce&tr=udp%3A%2F%2Fwx.kylinos.cn%3A46969%2Fannounce&xl=4386215936
```

## 1.5. 创建网卡

网卡工具下载到指定目录下进行安装
<img width="1164" height="300" alt="image" src="https://github.com/user-attachments/assets/7250a61e-8c47-4140-b5b2-7bc4305810fa" />

记得勾选 TAP 适配器
<img width="753" height="582" alt="image" src="https://github.com/user-attachments/assets/8788831d-1f46-4303-b7fd-38ea7e9a0a13" />

安装在网卡指定目录下
<img width="759" height="575" alt="image" src="https://github.com/user-attachments/assets/534cde99-8dad-4ec1-a0c5-8dd2e5fc7f83" />

<img width="1050" height="527" alt="image" src="https://github.com/user-attachments/assets/c17c0667-bbd6-40df-82b1-88f15fbe772a" />

网卡重命名
<img width="1113" height="309" alt="image" src="https://github.com/user-attachments/assets/a1e34078-74f4-4400-87fa-a8c3eb5f1472" />

本地网络共享
<img width="987" height="558" alt="image" src="https://github.com/user-attachments/assets/a67d49b5-e066-48ab-bef6-8c30c762db39" />

## 1.6. 安装qemu

创建指定的目录，把指定的操作系统ios/qemu/QEMU_EFI.fd放到指定的目录下
<img width="1191" height="269" alt="image" src="https://github.com/user-attachments/assets/3b91d2ea-3cf4-4b6c-aefc-869e0b70e6fb" />

运行 qemu，安装在当前目录下
<img width="1068" height="450" alt="image" src="https://github.com/user-attachments/assets/c4bd0ac9-86d7-4ab8-ba4a-d0a5ed957c22" />

使用 qemu 生成一个硬盘文件，进入到qemu的安装目录（D:\test_arm\qemu_arm64\qemu），打开cmd命令行

```shell
# 注意路径不同

qemu-img create -f qcow2 D:\test_arm\qemu_arm64\Kylin-Server-10-SP2-aarch64.img 50G
```
<img width="1350" height="240" alt="image" src="https://github.com/user-attachments/assets/1a50aac0-5dd2-453c-8f13-4ffbe398b54b" />

成功会生成一个文件
<img width="1365" height="395" alt="image" src="https://github.com/user-attachments/assets/69a93389-8a98-4f48-8544-29a52df04034" />

## 1.7. 安装银河麒麟操作系统

进入到 qemu 所在位置（D:\test_arm\qemu_arm64），打开cmd执行安装命令
```shell
# 注意路径不同

qemu-system-aarch64 -m 4000 -cpu cortex-a72 -smp 4,cores=4,threads=1,sockets=1 -M virt -bios D:\test_arm\qemu_arm64\QEMU_EFI.fd -net nic -net tap,ifname=tap1212 -device nec-usb-xhci -device usb-kbd -device usb-mouse -device VGA -drive if=none,file=D:\ISO\Kylin-Server-10-SP2-aarch64-Release-Build09-20210524.iso,id=cdrom,media=cdrom -device virtio-scsi-device -device scsi-cd,drive=cdrom -drive if=none,file=D:\test_arm\qemu_arm64\Kylin-Server-10-SP2-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0

-m 4000 表示分配给虚拟机的内存最大4000MB，可以直接使用 -m 4G

-cpu cortex-a72 指定CPU类型，还可以选择cortex-a53、cortex-a57等

-smp 4,cores=4,threads=1,sockets=1 指定虚拟机最大使用的CPU核心数等

-M virt 指定虚拟机类型为virt，具体支持的类型可以使用 qemu-system-aarch64 -M help 查看

-bios D:\test_arm\qemu_arm64\QEMU_EFI.fd 指定UEFI固件文件

-net tap,ifname=tap1212 启用网络功能（ifname=tap1212中的tap1212请修改为前面步骤中自己修改后的网卡名称）

-device nec-usb-xhci -device usb-kbd -device usb-mouse 启用USB鼠标等设备

-device VGA 启用VGA视图，对于图形化的Linux这条很重要！

-drive if=none,file=D:\ISO\Kylin-Server-10-SP2-aarch64-Release-Build09-20210524.iso,id=cdrom,media=cdrom 指定光驱使用镜像文件

-device virtio-scsi-device -device scsi-cd,drive=cdrom 指定光驱硬件类型

-drive if=none,file=D:\test_arm\qemu_arm64\Kylin-Server-10-SP2-aarch64.img 指定硬盘镜像文件
```

弹出 qemu 启动界面回车就行，启动过程会有点卡，等待即可
<img width="1347" height="471" alt="image" src="https://github.com/user-attachments/assets/2b858596-ece2-402f-a4e0-a2c015d261d2" />

配置安装信息
<img width="734" height="495" alt="image" src="https://github.com/user-attachments/assets/c44755ef-b6ce-4d73-9b93-d1a750c83bf1" />

软件选择可选带UKUIGUI的服务器，也可最小化安装（安装相对会简单快捷，后续可以使用别的图形化工具）
<img width="969" height="444" alt="image" src="https://github.com/user-attachments/assets/d9fda5c3-94a4-447b-90e8-a20e24052497" />

上面创建了虚拟网卡这里才能显示，（注意，手动配置网络的时候网关不能配置错误，否则虚拟机连不上外网）
<img width="1329" height="447" alt="image" src="https://github.com/user-attachments/assets/71cf1bfb-0018-4757-a578-c8b95ea9f40a" />

安装过程非常非常慢，安装完成后重启系统，配置许可信息
<img width="696" height="279" alt="image" src="https://github.com/user-attachments/assets/f184760a-b958-49c1-90eb-316dbe307801" />

输入密码登录即可

<img width="654" height="225" alt="image" src="https://github.com/user-attachments/assets/c7982186-06c8-40d7-a872-365cbd410fd5" />

## 1.8. 启动虚拟机

安装好之后，我们需要再次启动（无需再次指定iso文件启动），进入到qemu所在位置（D:\test_arm\qemu_arm64），进入到cmd命令行，执行启动命令
```shell
# 无需再次指定iso文件启动

qemu-system-aarch64 -m 4000 -cpu cortex-a72 -smp 4,cores=4,threads=1,sockets=1 -M virt -bios D:\test_arm\qemu_arm64\QEMU_EFI.fd -net nic -net tap,ifname=tap1212 -device nec-usb-xhci -device usb-kbd -device usb-mouse -device VGA -drive if=none,file=,id=cdrom,media=cdrom -device virtio-scsi-device -device scsi-cd,drive=cdrom -drive if=none,file=D:\test_arm\qemu_arm64\Kylin-Server-10-SP2-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0
```
