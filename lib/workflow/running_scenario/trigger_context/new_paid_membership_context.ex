defmodule Workflow.RunningScenario.TriggerContext.NewPaidMembershipContext do
  @enforce_keys [:customer_id, :membership_id, :membership_plan_id]
  defstruct [:customer_id, :membership_id, :membership_plan_id]

  @type t :: %__MODULE__{
          customer_id: integer,
          membership_plan_id: String.t()
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(
          %{
            customer_id: customer_id,
            membership_id: membership_id,
            membership_plan_id: membership_plan_id
          },
          opts
        ) do
      Jason.Encode.map(
        %{
          "type" => "new_paid_membership",
          "customer_id" => customer_id,
          "membership_id" => membership_id,
          "membership_plan_id" => membership_plan_id
        },
        opts
      )
    end
  end
end
