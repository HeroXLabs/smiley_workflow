defmodule Workflow.RunningScenario.TriggerContext.FormResponseContext do
  @enforce_keys [:customer_id, :response_id]
  defstruct [:customer_id, :response_id]

  @type t :: %__MODULE__{
          customer_id: integer,
          response_id: integer
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{customer_id: customer_id, response_id: response_id}, opts) do
      Jason.Encode.map(
        %{
          "type" => "form_response_created",
          "customer_id" => customer_id,
          "response_id" => response_id
        },
        opts
      )
    end
  end
end
