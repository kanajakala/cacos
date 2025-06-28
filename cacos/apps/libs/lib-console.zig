const sc = @import("../libs/lib-syscalls.zig");
const db = @import("../libs/lib-debug.zig");

pub fn print(string: []const u8) void {
    _ = sc.syscall(sc.Syscalls.print, @intFromPtr(string.ptr), string.len, 0, 0);
}

pub fn printErr(string: []const u8) void {
    _ = sc.syscall(sc.Syscalls.print_err, @intFromPtr(string.ptr), string.len, 0, 0);
}

pub fn printChar(value: u8) void {
    _ = sc.syscall(sc.Syscalls.print_char, value, 0, 0, 0);
}

///get the word at position n 
///if n=0 we expect to get the first word in the string
pub fn wordInString(n: usize, string: []const u8) []const u8 {
   //words are separated by spaces
   var start_of_word: usize = 0;
   var end_of_word: usize = 0;
   var i: usize = 0;
   var number_of_spaces: usize = 0;

   //we find the start of the word
   while (i < string.len and number_of_spaces < n) : (i += 1) {
       if (string[i] == ' ') {
           start_of_word = i+1;
           number_of_spaces+=1;
       }
   }

    //we dont need to count he previous space
    // i += 1;

   //we also need to find the end of the word
   while (i < string.len) : (i += 1) {
       if (string[i] == ' ') {
           break;
       }
   }

    end_of_word = i;

   //we now have the right values for the start and end of the words
   return string[start_of_word..end_of_word];

}
