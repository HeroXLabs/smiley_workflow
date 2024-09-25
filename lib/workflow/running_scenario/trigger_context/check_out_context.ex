defmodule Workflow.RunningScenario.TriggerContext.CheckOutContext do
  @enforce_keys [:customer_id, :check_out_id, :stars_earned]
  defstruct [:customer_id, :check_out_id, :stars_earned]

  @type t :: %__MODULE__{
          customer_id: integer,
          check_out_id: term,
          stars_earned: integer
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{customer_id: customer_id, check_out_id: check_out_id, stars_earned: stars_earned}, opts) do
      Jason.Encode.map(
        %{
          "type" => "check_out",
          "customer_id" => customer_id,
          "check_out_id" => check_out_id,
          "stars_earned" => stars_earned
        },
        opts
      )
    end
  end
end
