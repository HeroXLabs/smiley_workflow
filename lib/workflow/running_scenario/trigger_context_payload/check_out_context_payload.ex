defmodule Workflow.RunningScenario.TriggerContextPayload.CheckOutContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{Business, Customer}

  defmodule CheckOut do
    @derive Jason.Encoder
    @enforce_keys [:id, :services]
    defstruct [:id, :services]

    @type t :: %__MODULE__{
            id: String.t(),
            services: list(integer)
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
        "last_visit_at" => DateTime.to_unix(customer.last_visit_at),
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "check_in" => %{
          "services" => check_out.services
        }
      }
    end
  end
end
