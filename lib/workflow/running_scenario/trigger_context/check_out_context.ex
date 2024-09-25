defmodule Workflow.RunningScenario.TriggerContext.CheckOutContext do
  @enforce_keys [:customer_id, :check_out_id]
  defstruct [:customer_id, :check_out_id]

  @type t :: %__MODULE__{
          customer_id: integer,
          check_out_id: term
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{customer_id: customer_id, check_out_id: check_out_id}, opts) do
      Jason.Encode.map(
        %{
          "type" => "check_out",
          "customer_id" => customer_id,
          "check_out_id" => check_out_id
        },
        opts
      )
    end
  end
end
