defmodule Workflow.RunningScenario.TriggerContextPayload.Customer do
  @derive Jason.Encoder
  @enforce_keys [:id, :first_name, :phone_number, :tags, :visits_count, :last_visit_at]
  defstruct [:id, :first_name, :phone_number, :tags, :visits_count, :last_visit_at]

  @type t :: %__MODULE__{
          id: integer,
          first_name: String.t(),
          phone_number: String.t(),
          tags: list(String.t()),
          visits_count: integer,
          last_visit_at: DateTime.t()
        }
end
