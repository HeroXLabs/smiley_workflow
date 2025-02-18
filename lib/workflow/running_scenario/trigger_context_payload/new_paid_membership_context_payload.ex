defmodule Workflow.RunningScenario.TriggerContextPayload.NewPaidMembershipContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{Business, Customer}
  alias Workflow.Dates

  defmodule Membership do
    @derive Jason.Encoder
    @enforce_keys [:id, :title, :price, :plan_frequency]
    defstruct [:id, :title, :price, :plan_frequency]

    @type t :: %__MODULE__{
            id: String.t(),
            title: String.t(),
            price: number,
            plan_frequency: String.t()
          }
  end

  @derive Jason.Encoder
  @enforce_keys [:business, :customer, :membership]
  defstruct [:business, :customer, :membership]

  @type t :: %__MODULE__{
          business: Business.t(),
          customer: Customer.t(),
          membership: Membership.t()
        }

  defimpl Workflow.RunningScenario.ConditionsPayload, for: __MODULE__ do
    alias Workflow.RunningScenario.TriggerContextPayload.NewPaidMembershipContextPayload

    def to_conditions_payload(%NewPaidMembershipContextPayload{
          business: business,
          customer: customer,
          membership: membership
        }) do
      %{
        "first_name" => customer.first_name,
        "phone_number" => customer.phone_number,
        "tags" => customer.tags,
        "visits_count" => customer.visits_count,
        "last_visit_at" => Dates.to_datetime_unix_optional(customer.last_visit_at),
        "has_upcoming_appointments" => customer.has_upcoming_appointments,
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "membership" => %{
          "id" => membership.id,
          "title" => membership.title,
          "price" => membership.price,
          "plan_frequency" => membership.plan_frequency
        }
      }
    end
  end
end
