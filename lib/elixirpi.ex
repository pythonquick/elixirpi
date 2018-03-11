defmodule Elixirpi do

  def main(args) do
    args |> parse_args |> process
  end

  def show_usage() do
    IO.puts "provide command-line switches:"
    IO.puts "--mode : either server or worker. Start one server, start one or more workers"
    IO.puts "--name : the node name, e.g. master@myhost.local"
    IO.puts "--mastenode : specify this switch only when --mode set to worker"
  end

  def process([]) do
    show_usage()
  end

  def process(options) do
    case options do
      [mode: "server", name: node_name] ->
        start_server(node_name)
      [mode: "worker", name: node_name, masternode: master_node_name] ->
        start_worker(node_name, master_node_name)
      _ ->
        show_usage()
    end
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [
        mode: :string,
        name: :string,
        masternode: :string
      ]
    )
    options
  end

  defp start_server(node_name) do
    Node.start String.to_atom(node_name)
    Elixirpi.Collector.start()
  end

  defp start_worker(node_name, master_node_name) do
    Node.start String.to_atom(node_name)
    Node.connect String.to_atom(master_node_name)
    :global.sync()
    Elixirpi.Worker.run()
  end
end
