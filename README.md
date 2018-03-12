# Elixirpi

This repository contains the Elixir program to calculate the value of pi to
10000 digits. 

It uses a server node to distribute work and collect the results.
It uses one or more worker nodes to do the calculation.

## Setting up nodes to work accross the network

Make sure each machine that is to run a worker node has the same "erlang cookie"
so that other nodes on the network can connect.

A cookie is a random string and is stored in the file .erlang_.cookie in the
home directory. If you already have Elixir running on a machine, it might
already have a .erlang.cookie file that can then be copied to each of the
network hosts. In my case, copying the file from the MacOS machine to each
of the hosts (alpha, beta, charlie and delta):

```
scp ~/.erlang.cookie pi@alpha:.erlang.cookie
scp ~/.erlang.cookie pi@beta:.erlang.cookie
scp ~/.erlang.cookie pi@charlie:.erlang.cookie
scp ~/.erlang.cookie pi@delta:.erlang.cookie
```

## Install the dependency

This project uses the hex.pm module `Decimals` for the calculation of pi, to
have an arbitrary precision for decimal numbers.

Run the following `mix` command to install the dependency:

    mix deps.get

## Compile and create an executable

Run the following `mix` command to create a "elixirpi" executable:

    mix escript.build

## Run the server node

The server node starts up a GenServer in the Elixirpi.Collector module. 
Run the executable with the following switches, to start the server:

    ./elixirpi --mode=server --name=master@gmac.local

Note: in the example above, the node name "master@gmac.local" uses the host name
"gmac.local". Change the name value to match the host name of your machine.

When the server has no more work to be done, it will write the resulting value
of pi to the file pi.txt

## Run the worker node

The worker node will connect to a server node and requests work to be done (the
work is a list of digit positions of pi to calculate). Once the worker
calculated the result, it sends back the result to the server node and asks for
the next chunk of work.

Run the executable with the following switches, to start the worker:

    ./elixirpi --mode=worker --name=worker1@gmac.local

Note: in the example above, the node name "pi@alpha.local" uses the host name
"alpha.local". Change the name value to match the host name of your machine.

## 

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixirpi](https://hexdocs.pm/elixirpi).

