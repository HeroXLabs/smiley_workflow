defmodule Workflow.RunningScenario.TriggerContext.CheckInContext do
  @enforce_keys [:customer_id, :check_in_id]
  defstruct [:customer_id, :check_in_id]

  @type t :: %__MODULE__{
          customer_id: integer,
          check_in_id: term
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{customer_id: customer_id, check_in_id: check_in_id}, opts) do
      Jason.Encode.map(
        %{
          "type" => "check_in",
          "customer_id" => customer_id,
          "check_in_id" => check_in_id
        },
        opts
      )
    end
  end
end
