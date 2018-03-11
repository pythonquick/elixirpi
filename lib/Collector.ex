defmodule Elixirpi.Collector do
  use GenServer
  alias Decimal, as: D
  @process_name :collector_process_name
  @digit_batch_size 8
  @target_hex_digits 10000
  @precision div(@target_hex_digits * 4, 3)

  def start do
    D.set_context(%D.Context{D.get_context | precision: @precision}) 
    digit_positions = Enum.reduce(@target_hex_digits..0, [], &([&1 | &2]))
    exponent_cache = {0, D.new(1)} # keep track of highest sixteen-power. sixteen to power 0 is 1
    pi = D.new(0) # Initial value
    {:ok, pid} = GenServer.start_link(__MODULE__, {pi, digit_positions, exponent_cache})
    :global.register_name(@process_name, pid)

    # Serve worker requests - do not exit
    :timer.sleep(:infinity)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call(:next_digit_positions, _from, {pi, digit_positions, exponent_cache}) do
    {next_digits, remaining}  = Enum.split(digit_positions, @digit_batch_size)
    output_progress(next_digits, pi)
    {:reply, {next_digits, exponent_cache}, {pi, remaining, exponent_cache}}
  end

  def handle_call(:pi, _from, {pi, digit_positions, exponent_cache}) do
    { :reply, pi, {pi, digit_positions, exponent_cache} }
  end

  def handle_cast({:update_pi, additional_term, new_sixteen_pow}, {pi, digit_positions, sixteen_pow}) do
    D.set_context(%D.Context{D.get_context | precision: @precision}) 
    {new_sixteen_exp, _} = new_sixteen_pow
    {current_sixteen_exp, _} = sixteen_pow
    highest_sixteen_pow = if new_sixteen_exp > current_sixteen_exp, do: new_sixteen_pow, else: sixteen_pow
    updated_pi = D.add(pi, additional_term)
    {:noreply, {updated_pi, digit_positions, highest_sixteen_pow}}
  end

  def output_progress([], pi) do
    IO.puts "No more digits to process."
    if !File.exists?("pi.txt") do
      IO.puts "writing pi.txt file"
      {:ok, file} = File.open "pi.txt", [:write]
      File.close file

      {:ok, file} = File.open "pi.txt", [:write]
      pi_string = D.to_string(pi, :normal)
      IO.binwrite file, String.slice(pi_string, 0..@target_hex_digits+2)
      File.close file
    end
  end

  def output_progress(next_digits, _pi) do
    IO.puts "Scheduling calculation of digit positions: #{inspect next_digits}"
  end

  def process_pid do
    :global.whereis_name(@process_name)
  end

  def next_digits do
    GenServer.call(process_pid(), :next_digit_positions)
  end

  def update_pi(additional_term, exponent_cache) do
    GenServer.cast(process_pid(), {:update_pi, additional_term, exponent_cache})
  end

  def precision do
    @precision
  end

  def pi do
    GenServer.call(process_pid(), :pi)
  end
end
