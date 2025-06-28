const console = @import("../libs/lib-console.zig");
const db = @import("../libs/lib-debug.zig");

//this is an enum describing all possible syscalls
//later a script will automaticaly import it into the lib-syscall
pub const Syscalls = enum(u64) {
    //console:
    print, //print a string to screen
    print_char, //print a char, usefull when the string is not hard-coded
    print_err, //prints an error

    //filesystem:
    create, //create a new node
    open, //return a File struct describing the file
    read, //read from a node
    read_to_buffer, //read to a buffer provided by the caller
    write, //write to a node
    write_from_buffer, //write from a buffer provided by the caller
    get_childs, //get all the childs of a node in a memory page
    node_name_to_buffer, //get the name of a node

    //memory:
    alloc, //allocate a page
    valloc, //allocate n bytes at an address
    free, //free a page

    //executables:
    load, //load an elf file
    exec, //execute an elf file

    //debug:
    debug, //print a string to the debug console
    debug_value, //debug ann integer value
};

//these are the erros that a syscall can return
pub const sys_err = error {
    failed_to_print,
    no_such_file,
    index_overflow,
    unknown_syscall,
    invalid_debug_value_mode,
};

///trigger a system interrupt using these arguments and returns a value
pub fn syscall(stype: Syscalls, arg0: u64, arg1: u64, arg2: u64, arg3: u64) u64 {
    //push the arguments on the stack
    //and get the return value
    const value: u64 = asm volatile (
    //pass the arguments
    //trigger the syscall interrupt
        \\int $34        
        : [ret] "={r8}" (-> u64), //return the return value which the handlers has put in r8
        : [syscall] "{r8}" (@intFromEnum(stype)),
          [arg0] "{r9}" (arg0),
          [arg1] "{r10}" (arg1),
          [arg2] "{r11}" (arg2),
          [arg3] "{r12}" (arg3),
    );

    const error_value: u64 = asm volatile (
        "" //we dont need any instructions
        : [ret] "={r9}" ( -> u64) //we get the value in r9 which contains the error code
    );

    //check for errors
    //on error the return value is always 0, and r9 contains an error code
    //when there are no errors the return value can be 0, but r9 is always 0 (error code "no error")
    if (value == 0 and error_value != 0) {
        db.print("\nThere has been an error calling a syscall");
        //we handle the error
        //we need to remove 1 because the error index start at 0, so we add one to the error code in the syscall handler
        const syscall_error = @errorFromInt(@as(u16, @truncate(error_value)) - 1);
        
        //we print the error name so that the user knows there has been an error
        console.printErr("\n[SYSCALL ERROR] ");
        console.printErr(@errorName(syscall_error));
        console.print("\n");
    }

    return value;
}
