# CacOS
```
 ____                     _____   ____       
/\  _`\                  /\  __`\/\  _`\     
\ \ \/\_\     __      ___\ \ \/\ \ \,\L\_\   
 \ \ \/_/_  /'__`\   /'___\ \ \ \ \/_\__ \   
  \ \ \L\ \/\ \L\.\_/\ \__/\ \ \_\ \/\ \L\ \ 
   \ \____/\ \__/.\_\ \____\\ \_____\ `\____\
    \/___/  \/__/\/_/\/____/ \/_____/\/_____/
                                             
                                             

```


## Coherent and Cohesive Operating System

(It is absolutely none of these words :D )


## The Plan
    
 Rewrite

============================ => STAGE 0 (bootloader) ✔️

    |> Implement Bootboot protocol ✔️

============================ => STAGE 1 (core-functionnality) `kernel/core`

 -> framebuffer
    |> basic functions (put, square, ...)                     `core/display`
    |> display font                                           `core/font`
 
 -> memory
    |> page allocation                                        `core/alloc`
    |> page protection                                        `core/alloc`
 
 -> interrupts
    |> IDT                                                    `core/idt`
    |> GDT                                                    `core/gdt`

 -> error handling

 -> Process management

 -> Filesystem                                                `core/fs`
    |> rootfs
        * use zig structures for everything
        * create file
        * delete file
        * set data
        * append data
        * change file attributes

 -> Load binaries

============================ => STAGE 2 (drivers and processes)

 -> Keyboard
 -> Console

============================ => STAGE 3 (apps)

 -> Filesystem utils (cd mv rm touch cat pwd ls)
 -> Base commands (echo uname ps...)
 -> ...





### Dependecies

 To run this project you will need zig 13, the ld linker, git, and qemu-system-x86_64
 
### How to run ?

 Simply run `$ zig build run` to execute, dependecies should be downloaded automatically
