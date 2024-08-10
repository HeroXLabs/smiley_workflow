defmodule Workflow.RunningScenario.TriggerContextPayload.CheckInContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{Business, Customer}
  alias Workflow.Dates

  defmodule CheckIn do
    @derive Jason.Encoder
    @enforce_keys [:id, :services]
    defstruct [:id, :services]

    @type t :: %__MODULE__{
            id: String.t(),
            services: list(integer)
          }
  end

  @derive Jason.Encoder
  @enforce_keys [:business, :customer, :check_in]
  defstruct [:business, :customer, :check_in]

  @type t :: %__MODULE__{
          business: Business.t(),
          customer: Customer.t(),
          check_in: CheckIn.t()
        }

  defimpl Workflow.RunningScenario.ConditionsPayload, for: __MODULE__ do
    alias Workflow.RunningScenario.TriggerContextPayload.CheckInContextPayload

    def to_conditions_payload(%CheckInContextPayload{
          business: business,
          customer: customer,
          check_in: check_in
        }) do
      %{
        "first_name" => customer.first_name,
        "phone_number" => customer.phone_number,
        "tags" => customer.tags,
        "visits_count" => customer.visits_count,
        "last_visit_at" => Dates.to_datetime_unix_optional(customer.last_visit_at),
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "check_in" => %{
          "services" => check_in.services
        }
      }
    end
  end
end
