defmodule Workflow.RunningScenario.TriggerContextPayload.CancelAppointmentContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{Business, Customer}

  defmodule Employee do
    @derive Jason.Encoder
    @enforce_keys [:id, :first_name, :phone_number]
    defstruct [:id, :first_name, :phone_number]

    @type t :: %__MODULE__{
            id: integer,
            first_name: String.t(),
            phone_number: String.t()
          }
  end

  defmodule Appointment do
    @derive Jason.Encoder
    @enforce_keys [:id, :start_at, :services, :employees]
    defstruct [:id, :start_at, :services, :employees]

    @type t :: %__MODULE__{
            id: String.t(),
            start_at: DateTime.t(),
            services: list(String.t()),
            employees: list(String.t())
          }
  end

  @derive Jason.Encoder
  @enforce_keys [:business, :customer, :appointment, :employee_1]
  defstruct [:business, :customer, :appointment, :employee_1]

  @type t :: %__MODULE__{
          business: Business.t(),
          customer: Customer.t(),
          appointment: Appointment.t(),
          employee_1: Employee.t()
        }

  defimpl Workflow.RunningScenario.ConditionsPayload, for: __MODULE__ do
    alias Workflow.RunningScenario.TriggerContextPayload.CancelAppointmentContextPayload

    def to_conditions_payload(%CancelAppointmentContextPayload{
          business: business,
          customer: customer,
          appointment: appointment,
          employee_1: employee_1
        }) do
      %{
        "first_name" => customer.first_name,
        "phone_number" => customer.phone_number,
        "masked_phone_number" => "******" <> String.slice(customer.phone_number, -4..-1),
        "tags" => customer.tags,
        "visits_count" => customer.visits_count,
        "last_visit_at" => DateTime.to_unix(customer.last_visit_at),
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "appointment" => %{
          "start_at" => appointment.start_at,
          "services" => appointment.services,
          "employees" => appointment.employees
        },
        "employee_1" => %{
          "id" => employee_1.id,
          "first_name" => employee_1.first_name,
          "phone_number" => employee_1.phone_number
        }
      }
    end
  end
end
