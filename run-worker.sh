epmd -daemon
./elixirpi --mode=worker --name=worker@`hostname` --masternode=master@`hostname`
