defmodule Workflow.RunningScenario.TriggerContext.CancelAppointmentContext do
  @enforce_keys [:customer_id, :appointment_id]
  defstruct [:customer_id, :appointment_id]

  @type t :: %__MODULE__{
          customer_id: integer,
          appointment_id: term
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{customer_id: customer_id, appointment_id: appointment_id}, opts) do
      Jason.Encode.map(
        %{
          "type" => "cancel_appointment",
          "customer_id" => customer_id,
          "appointment_id" => appointment_id
        },
        opts
      )
    end
  end
end
