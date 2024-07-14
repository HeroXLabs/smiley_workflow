defmodule Workflow.Filter do
  defmodule Incomplete do
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule FilterConditions do
    alias Workflow.{TypedConditions, Template}
    @type t :: TypedConditions.t()

    def new(raw_conditions) do
      with {:ok, conditions} <-
             TypedConditions.parse_conditions(raw_conditions, &Template.conditions_mapping/1) do
        {:ok, conditions}
      end
    end
  end

  @enforce_keys [:conditions, :raw_conditions]
  defstruct [:conditions, :raw_conditions]

  @type t :: %__MODULE__{conditions: FilterConditions.t(), raw_conditions: binary}

  def new(%{"conditions" => raw_conditions}) do
    with {:ok, conditions} <- FilterConditions.new(raw_conditions) do
      {:ok, %__MODULE__{conditions: conditions, raw_conditions: raw_conditions}}
    end
  end

  def new(_) do
    {:ok, %Incomplete{}}
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{raw_conditions: raw_conditions}, opts) do
      Jason.Encode.string(raw_conditions, opts)
    end
  end

  def from_json(raw_conditions) do
    new(%{"conditions" => raw_conditions})
  end
end
