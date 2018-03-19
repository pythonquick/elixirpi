defmodule Elixirpi.Collector do
  use GenServer
  alias Decimal, as: D
  @process_name :collector_process_name
  @digit_batch_size 40
  @target_hex_digits 10000
  @precision div(@target_hex_digits * 4, 3)

  def start do
    digit_positions = Enum.reduce(@target_hex_digits..0, [], &([&1 | &2]))
    digits_pending = []
    exponent_cache = {0, D.new(1)} # keep track of highest sixteen-power. sixteen to power 0 is 1
    pi = D.new(0) # Initial value
    {:ok, pid} = GenServer.start_link(__MODULE__, {pi, digit_positions, digits_pending, exponent_cache})
    :global.register_name(@process_name, pid)

    # Serve worker requests - do not exit
    IO.puts "Started server. Target is pi to #{@target_hex_digits} decimal places"
    :timer.sleep(:infinity)
  end

  ##############################################################################
  # GenServer callbacks
  ##############################################################################

  def handle_call(:next_digit_positions, _from, {pi, [], digits_pending, exponent_cache}) do
    {assigned_digits, remaining}  = Enum.split(digits_pending, @digit_batch_size)
    digits_pending = remaining ++ assigned_digits
    output_progress(assigned_digits, digits_pending, pi)
    {:reply, {assigned_digits, exponent_cache}, {pi, [], digits_pending, exponent_cache}}
  end

  def handle_call(:next_digit_positions, _from, {pi, digit_positions, digits_pending, exponent_cache}) do
    {assigned_digits, remaining}  = Enum.split(digit_positions, @digit_batch_size)
    digits_pending = Enum.into(assigned_digits, digits_pending)
    output_progress(assigned_digits, digits_pending, pi)
    {:reply, {assigned_digits, exponent_cache}, {pi, remaining, digits_pending, exponent_cache}}
  end

  def handle_cast({:update_pi, digit_position, additional_term, new_sixteen_pow}, {pi, digit_positions, digits_pending, sixteen_pow}) do
    D.set_context(%D.Context{D.get_context | precision: @precision}) 
    {new_sixteen_exp, _} = new_sixteen_pow
    {current_sixteen_exp, _} = sixteen_pow
    highest_sixteen_pow = if new_sixteen_exp > current_sixteen_exp, do: new_sixteen_pow, else: sixteen_pow
    digits_pending = List.delete(digits_pending, digit_position)
    updated_pi = D.add(pi, additional_term)
    {:noreply, {updated_pi, digit_positions, digits_pending, highest_sixteen_pow}}
  end

  def init(args) do
    {:ok, args}
  end

  ##############################################################################
  # Public functions. To be used by the Worker process:
  ##############################################################################

  def next_digits do
    GenServer.call(process_pid(), :next_digit_positions)
  end

  def update_pi(digit_position, additional_term, exponent_cache) do
    GenServer.cast(process_pid(), {:update_pi, digit_position, additional_term, exponent_cache})
  end

  def precision do
    @precision
  end

  def process_pid do
    :global.whereis_name(@process_name)
  end

  ##############################################################################
  # Private helper functions:
  ##############################################################################
  defp output_progress([], [], pi) do
    file_name = "pi-#{@target_hex_digits}.txt"
    IO.puts "Processed all digits. Writing #{file_name}"
    {:ok, file} = File.open file_name, [:write]
    pi_string = D.to_string(pi, :normal)
    IO.binwrite file, String.slice(pi_string, 0..@target_hex_digits + 2)
    File.close file
    System.stop
  end

  defp output_progress(assigned_digits, _pending_digits, _pi) do
    [first_assigned_digit | _tail] = assigned_digits
    IO.puts "First digit of next digit batch assigned: #{first_assigned_digit}."
  end
end
