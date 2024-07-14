defmodule Workflow.Delay do
  defmodule Incomplete do
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule DelayUnit do
    @valid_types [:days, :hours, :minutes, :seconds]
    @type t :: :days | :hours | :minutes | :seconds

    def new(value) do
      value = String.to_atom(value)

      if value in @valid_types do
        {:ok, value}
      else
        {:error, "Invalid delay unit"}
      end
    end
  end

  defmodule DelayValue do
    @type t :: non_neg_integer

    def new(value) when is_integer(value) do
      if value >= 0 do
        {:ok, value}
      else
        {:error, "Invalid delay value"}
      end
    end

    def new(value) when is_binary(value) do
      case Integer.parse(value) do
        {value, ""} -> new(value)
        _ -> {:error, "Invalid delay value"}
      end
    end
  end

  @derive Jason.Encoder
  @enforce_keys [:delay_value, :delay_unit]
  defstruct [:delay_value, :delay_unit]

  @type delay_unit :: DelayUnit.t()
  @type t :: %__MODULE__{delay_value: integer, delay_unit: delay_unit}

  def new(%{"delay_value" => delay_value, "delay_unit" => delay_unit}) do
    with {:ok, delay_unit} <- DelayUnit.new(delay_unit),
         {:ok, delay_value} <- DelayValue.new(delay_value) do
      {:ok, %__MODULE__{delay_value: delay_value, delay_unit: delay_unit}}
    end
  end

  def new(_) do
    {:ok, %Incomplete{}}
  end

  def in_seconds(%__MODULE__{delay_value: delay_value, delay_unit: :seconds}) do
    delay_value
  end

  def in_seconds(%__MODULE__{delay_value: delay_value, delay_unit: :minutes}) do
    delay_value * 60
  end

  def in_seconds(%__MODULE__{delay_value: delay_value, delay_unit: :hours}) do
    delay_value * 60 * 60
  end

  def in_seconds(%__MODULE__{delay_value: delay_value, delay_unit: :days}) do
    delay_value * 60 * 60 * 24
  end
end

