<h1 align=center>CaCOS</h1>
<h4 align=center>coherent and cohesive operating system</h4>

CaCOS is a hobby OS, currently in rewrite. It's goal is to be functional, as well as written in elegant zig code, as much as possible. In the current rewrite there is font displaying and basic memory management. 


# The Plan
 
### STAGE 0: boot-loader  ✔️

* implement the bootboot boot protocol and launch a dummy kernel ✔️

### STAGE 1: core-functionality

* frame-buffer ✔️
    * basic functions (put_pixel, square, ...) -> `core/display` ✔️
    * display font -> `core/font` ✔️
      
* memory
    * page allocation ->  `core/alloc` ✔️
    * page protection ->`core/alloc`
      
* interrupts ✔️
  * IDT  ->  `cpu/idt` ✔️
  * GDT -> `cpu/gdt` ✔️

* error handling

* Process management

* Filesystem
   * rootfs ->`core/fs`
        * leverage structures for nodes ✔️
        * create file✔️
        * delete file
        * set data✔️
        * append data✔️
        * change file attributes

 * Syscalls

 * Load binaries and execute them

### STAGE 2: drivers and processes

 * Keyboard
 * Console

### STAGE 3: apps

* Filesystem utils (cd mv rm touch cat pwd ls)
 * Base commands (echo uname ps...)
 * ...

# Running the OS
> **NOTE:** the OS is currently in heavy development and the process to run the OS is not streamlined yet  

> **NOTE:** running on macos or windows has never been tested, though it should work fine

To run the os you have to clone the git project or download the project archive via github.
you can then run the following the command if you are on linux (or mac?)  
`qemu-system-x86_64 -drive format=raw,file=kernel/img/cacos.img`

# Building the OS
> **NOTE:** the build process is very unlikely to run on non-unix system, it may work on mac with some tweaking

you will need the following dependencies:
* [zig 13](https://ziglang.org/download/)
* [qemu-system-x86_6](https://www.qemu.org/download/#linux)
* [git](https://git-scm.com/)

running the following the following command will compile everything for you and run the os:  
`zig build run`

you can customize the build process by running specific steps:
* `zig build compile` generate an elf executable of the kernel
* `zig build setup` dowloads and build mkbootimg, bootboots utility program to generate bootable images
* `zig build gen` create a bootable image using mkbootimg
* `zig build run` run the previous steps and run the image in qemu
