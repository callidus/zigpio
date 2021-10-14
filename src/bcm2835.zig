const peripherals = @import("peripherals.zig");

const AddressRange = peripherals.AddressRange;

const std = @import("std");

/// A structure containin info about the BCM2835 chip
/// see this website which does a brilliant job of explaining everything
/// https://www.pieter-jan.com/node/15
/// The most important thing is to look at the BCM2835 peripheral manual (pi1 / p2)
/// and then see in section 1.2.3 how the register addresses in the manual relate with
/// the physical memory. Then see the Gpio section for an explanation of how to
/// operate the Gpio pins using the registers
pub const BoardInfo = struct {
    /// the *physical* address space of all peripherals
    pub const peripheral_addresses: AddressRange = .{ .start = 0x20000000, .len = 0xFFFFFF };
    // address space of the GPIO registers
    pub const gpio_registers = .{.start = peripheral_addresses.start + 0x200000, .len = 0xB0};
    // /// physical address space of the gpio registers GPFSEL{n} (function select)
    pub const gpfsel_registers: AddressRange = .{ .start = peripheral_addresses.start + 0x200000, .len = 6*4};
    /// physical address space of the gpio registers GPSET{n} (output setting)
    pub const gpset_registers : AddressRange = .{.start = gpfsel_registers.start + 0x1C , .len = 2*4};
    /// physical address space of the gpio registers GPCLR{n} (clearing pin output)
    pub const gpclr_registers : AddressRange = .{.start = gpfsel_registers.start + 0x28 , .len = 2*4};
    /// physical address space of the gpio registers GPLEV{n} (reading pin levels)
    pub const gplev_registers : AddressRange = .{.start = gpfsel_registers.start + 0x34, .len = 2*4 };

    /// the number of GPIO pins
    pub const NUM_GPIO_PINS = 53;
};

pub const Bcm2385GpioMemoryMapper = struct {
    const Self : type = @This();
    
    /// the GpioMemMapper interface
    memory_mapper : peripherals.GpioMemMapper,
    /// the raw bytes representing the memory mapping
    gpio_memory_mapping : []u8,

    pub fn init() !Self {
        const devgpiomem = try std.fs.openFileAbsolute("/dev/gpiomem", std.fs.File.OpenFlags{.read = true,.write = true});
        defer devgpiomem.close();

        return Self {
            //TODO remove hardcoded size!!!!!!!!!!!
            .gpio_memory_mapping =  try std.os.mmap(null, 0xB4, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.SHARED, devgpiomem.handle, 0),
            .memory_mapper = .{.map_fn = Self.memoryMap}
        };
       
    }

    pub fn deinit() void {
        // todo unmap the memory
        @compileError("todo implement");
    }

    pub fn memoryMap(interface : *peripherals.GpioMemMapper) !peripherals.GpioRegisterMemory {
        var self = @fieldParentPtr(Self, "memory_mapper", interface);
        return std.mem.bytesAsSlice(u32,self.gpio_memory_mapping);
    }
};