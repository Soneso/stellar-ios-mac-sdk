//! Owner fixture contract for the Soneso SDK CAP-85 integration tests.
//!
//! Holds executable tag entries: `set_executable` writes the persistent tag
//! entry whose value is the 32-byte hash of an already uploaded wasm, which
//! contracts created from an external reference naming this owner then run.
//! The fixture carries no authorization on purpose; every test account may
//! write tags.
#![no_std]
use soroban_sdk::{contract, contractimpl, BytesN, Env, String};

#[contract]
pub struct OwnerFixture;

#[contractimpl]
impl OwnerFixture {
    /// Stores `wasm_hash` as the executable this owner serves under `tag`.
    pub fn set_executable(env: Env, tag: String, wasm_hash: BytesN<32>) {
        env.executable_refs().set(&tag, &wasm_hash);
    }

    /// The wasm hash stored under `tag`, if any.
    pub fn get_executable(env: Env, tag: String) -> Option<BytesN<32>> {
        env.executable_refs().get(&tag)
    }
}
