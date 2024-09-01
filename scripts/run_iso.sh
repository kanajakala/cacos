echo ""
qemu-system-x86_64 -M q35 -m 2G -cdrom cacos.iso -boot d -debugcon  stdio --no-reboot -D logs -d int
