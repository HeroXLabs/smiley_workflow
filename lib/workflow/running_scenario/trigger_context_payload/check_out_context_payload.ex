defmodule Workflow.RunningScenario.TriggerContextPayload.CheckOutContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{Business, Customer}
  alias Workflow.Dates

  defmodule CheckOut do
    @derive Jason.Encoder
    @enforce_keys [:id, :services, :service_categories, :stars_earned]
    defstruct [:id, :services, :service_categories, :stars_earned]

    @type t :: %__MODULE__{
            id: String.t(),
            services: list(integer),
            service_categories: list(String.t()),
            stars_earned: integer
          }
  end

  @derive Jason.Encoder
  @enforce_keys [:business, :customer, :check_out]
  defstruct [:business, :customer, :check_out]

  @type t :: %__MODULE__{
          business: Business.t(),
          customer: Customer.t(),
          check_out: CheckOut.t()
        }

  defimpl Workflow.RunningScenario.ConditionsPayload, for: __MODULE__ do
    alias Workflow.RunningScenario.TriggerContextPayload.CheckOutContextPayload

    def to_conditions_payload(%CheckOutContextPayload{
          business: business,
          customer: customer,
          check_out: check_out
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
        "check_out" => %{
          "services" => check_out.services,
          "service_categories" => check_out.service_categories,
          "stars_earned" => check_out.stars_earned
        }
      }
    end
  end
end
