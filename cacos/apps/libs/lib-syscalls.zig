//this is an enum describing all possible syscalls
//later a script will automaticaly import it into the lib-syscall
pub const Syscalls = enum(u64) {
    print, //print a string to screen
    print_char, //print a char, usefull when the string is not hard-coded
    create, //create a new node
    open, //return a File struct describing the file
    read, //read from a node
    read_to_buffer, //read to a buffer provided by the caller
    write, //write to a node
    write_from_buffer, //write from a buffer provided by the caller
    alloc, //allocate a page
    malloc, //allocate multiple contigous pages
    valloc, //allocate n bytes at ann address
    free, //free a page
    load, //load an elf file
    exec, //execute an elf file
    debug, //print a string to the debug console
    debug_value, //debug ann integer value
};

///trigger a system interrupt using these arguments and returns a value
pub fn syscall(stype: Syscalls, arg0: u64, arg1: u64, arg2: u64, arg3: u64) u64 {
    //push the arguments on the stack
    return asm volatile (
    //pass the arguments
    //trigger the syscall interrupt
        \\int $34        
        : [ret] "={r8}" (-> u64),
        : [syscall] "{r8}" (@intFromEnum(stype)),
          [arg0] "{r9}" (arg0),
          [arg1] "{r10}" (arg1),
          [arg2] "{r11}" (arg2),
          [arg3] "{r12}" (arg3),
    );
    //return asm volatile ("movq %r13, %[ret]"
    //    : [ret] "={r13}" (-> u64), // output operand: put result in `result`
    //);
}
