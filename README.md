This is an experimental Ruby FFI interface to [Hiredis][0].

It exists mainly as a tool to teach me about [Ruby's FFI interface][1] as such
the location of `libhiredis.dylib` is hard-coded into `hiredis.rb`. If you want
to tinker with this yourself, make sure to amend that path.

  [0]: https://github.com/antirez/hiredis
  [1]: https://github.com/ffi/ffi
