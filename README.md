# Elixirpi

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixirpi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixirpi, "~> 0.1.0"}
  ]
end
```

## Raspberry Pi Node Setup

Make sure each Raspberry Pi node has the same "erlang cookie" so that other
nodes on the network can connect.

A cookie is a random string and is stored in the file .erlang_.cookie in the
home directory. If you already have Elixir running on a machine, it might
already have a .erlang.cookie file that can then be copied to each of the
Raspberry Pi nodes. In my case, copying the file from the MacOS machine to each
of the Raspberry PIs was as follows:

```
scp ~/.erlang.cookie pi@alpha:.erlang.cookie
scp ~/.erlang.cookie pi@beta:.erlang.cookie
scp ~/.erlang.cookie pi@charlie:.erlang.cookie
scp ~/.erlang.cookie pi@delta:.erlang.cookie
```



Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixirpi](https://hexdocs.pm/elixirpi).

