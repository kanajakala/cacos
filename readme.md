<h1 align=center>CaCOS</h1>
<h4 align=center>*Coherent and Cohesive Operating System*</h4>

CaCOS (*k-a-k-o-s*) is a simple hobby operating system. It's goal is to be functional and have a clean and elegant codebase, as much as possible. In the current rewrite there is a text console, a basic file system, and userland applications. You can see how the operating system is designed in the docs

---

# The Plan

Here are all the steps of the development of the os.

### Boot loader

- [x] implement the bootboot boot protocol

- [x] automate bootboot installation and image creation

### Core functionality

- [x] frame-buffer  
    - [x] basic functions  
    - [x] text display  

- [x] memory  
    - [x] page allocation and tracking  
    - [x] memory freeing  

- [x] system
    - [x] interrupt descriptor table (IDT) setup
    - [x] global descriptor table (GDT) setup
    - [x] interrupt service routine (ISR) setup

### advanced functionality

- [x] Keyboard driver
  
- [ ] Filesystem  
    - [x] basic ramfs and file structures  
    - [x] basic filesystem functions (*create*, *delete*, *read*, ...)  
    - [ ] path handling  
    - [ ] filesystem on disk  
  
- [x] Elf file loading  
    - [x] parse elf file  
    - [x] load and execute elf file  
     
- [x] system calls  
    - [x] call kernel code from apps  
    - [x] pass arguments and return errors  
     
- [x] error marshalling, through kernel and apps  
     
- [x] console  
    - [x] execute commands  
    - [x] standard text streams  

### apps

- [x] write simple apps leveraging elf loading and system calls

- [x] write a standard library providing basic functionality (*memory*, *filesystem*, ...)

- [x] build a complete set of utils, akin to busybox (*filesystem utils*, *text manipulation*, ...)

### Beyond

- [ ] threads and multi tasking  
    - [ ] write a scheduler  
    - [ ] context switches and multitasking  
    - [ ] multi threading  

- [ ] PCI driver

- [ ] support for hardware accelerated graphics

- [ ] mouse driver and support

- [ ] complete graphical interface

- [ ] networking

- [ ] porting linux binaries and utils

# Running the OS

> **NOTE:** the OS is currently in heavy development and the process to run the OS is not streamlined yet  

> **NOTE:** running on macos or windows has never been tested, though it should work fine

To run the CacOS you have to download the most recent image from the `releases` tab, and then run the following command: `qemu-system-x86_64 -drive format=raw,file=kernel/img/cacos.img`

Alternatively, you can clone the git directory (`git clone https://github.com/kanajakala/cacos.git CaCOS`), cd into it (`cd CaCOS`) and then run (`zig build run --release=small`)

currently there is not much you can do, you can type `motd` to show the motd, or `ls <dir>` to show the files in the provided directory

# Building the OS

you will need the following dependencies:
* [zig 15](https://ziglang.org/download/) for compiling the project
* [qemu-system-x86_6](https://www.qemu.org/download/#linux) to run the os
* [git](https://git-scm.com/) to clone the git repository
* zip for building bootboot (done automatically)

running the following command will download and compile bootboot, and it's image utility "*mkbootimg*", compile the OS code for you and run it in qemu:  
`zig build run`

you can customize the build process by running specific steps:
* `zig build compile` generate an elf executable of the kernel
* `zig build compile-apps` generate executables for the kernel apps
* `zig build setup` dowloads and build mkbootimg, bootboots utility program to generate bootable images
* `zig build gen` create a bootable image using mkbootimg
* `zig build run` run the all the previous steps, and run the image in qemu
