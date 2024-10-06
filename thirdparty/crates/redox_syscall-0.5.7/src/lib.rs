#![cfg_attr(not(any(feature = "std", test)), no_std)]
#![allow(unexpected_cfgs)] // why does this even exist?

#[cfg(test)]
extern crate core;

pub use self::{arch::*, data::*, error::*, flag::*, io::*, number::*};

#[cfg(target_arch = "aarch64")]
#[path = "arch/aarch64.rs"]
mod arch;

#[cfg(target_arch = "riscv64")]
#[path = "arch/riscv64.rs"]
mod arch;

#[cfg(target_arch = "x86")]
#[path = "arch/x86.rs"]
mod arch;

#[cfg(target_arch = "x86_64")]
#[path = "arch/x86_64.rs"]
mod arch;

/// Function definitions
#[cfg(feature = "userspace")]
pub mod call;

#[cfg(feature = "userspace")]
pub use call::*;

/// Complex structures that are used for some system calls
pub mod data;

pub mod dirent;

/// All errors that can be generated by a system call
pub mod error;

/// Flags used as an argument to many system calls
pub mod flag;

/// Functions for low level hardware control
pub mod io;

/// Call numbers used by each system call
pub mod number;

/// ABI for shared memory based signals
pub mod sigabi;

/// V2 scheme format
pub mod schemev2;

pub mod scheme;
pub use scheme::*;