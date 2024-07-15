defmodule Workflow.Trigger do
  defmodule TriggerType do
    @valid_types [:check_in, :check_out, :cancel_appointment, :new_paid_membership]
    @type t :: :check_in | :check_out | :cancel_appointment | :new_paid_membership

    def new(raw_type) do
      type = String.to_atom(raw_type)

      if Enum.member?(@valid_types, type) do
        {:ok, type}
      else
        {:error, "Invalid trigger type: #{raw_type}"}
      end
    end

    def value(type), do: to_string(type)
  end

  @enforce_keys [:type]
  defstruct [:type]

  @type t :: %__MODULE__{type: TriggerType.t()}

  # Context should be valid as it's from the default templates
  def new(type) do
    with {:ok, type} <- TriggerType.new(type) do
      {:ok, %__MODULE__{type: type}}
    end
  end
end
