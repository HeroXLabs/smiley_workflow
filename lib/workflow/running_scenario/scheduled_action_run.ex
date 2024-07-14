defmodule Workflow.RunningScenario.ScheduledActionRun do
  alias Workflow.RunningScenario.{ScheduledAction, Schedule}

  defmodule Schedule do
    @derive Jason.Encoder
    @enforce_keys [:job_id, :scheduled_at]
    defstruct [:job_id, :scheduled_at]

    @type t :: %__MODULE__{
            job_id: binary,
            scheduled_at: DateTime.t()
          }
  end

  @derive Jason.Encoder
  @enforce_keys [:action, :scheduled]
  defstruct [:action, :scheduled]

  @type t :: %__MODULE__{
          action: ScheduledAction.t(),
          scheduled: Schedule.t()
        }
end
