defmodule Workflow.Dto do
  defmodule NewStepDto do
    @derive Jason.Encoder
    @enforce_keys [:title, :description, :type, :trigger, :action, :value]
    defstruct [:title, :description, :type, :trigger, :action, :value]

    @type t :: %__MODULE__{
            title: binary,
            description: binary,
            type: binary,
            trigger: binary | nil,
            action: binary | nil,
            value: map | nil
          }
  end

  defmodule NewScenarioDto do
    alias Workflow.NewScenario

    @derive Jason.Encoder
    @enforce_keys [:workspace_id, :title, :trigger, :steps]
    defstruct [:workspace_id, :title, :trigger, :steps]

    @type t :: %__MODULE__{
            workspace_id: binary,
            title: binary,
            trigger: binary,
            steps: [NewStepDto.t()]
          }

    def from_domain(%NewScenario{} = new_scenario) do
      %NewScenarioDto{
        workspace_id: new_scenario.workspace_id,
        title: new_scenario.title,
        trigger: new_scenario.trigger.trigger,
        steps: [
          %NewStepDto{
            title: new_scenario.trigger.title,
            description: new_scenario.trigger.description,
            type: "trigger",
            trigger: new_scenario.trigger.trigger,
            action: nil,
            value: new_scenario.trigger.context
          }
        ]
      }
    end
  end

  defmodule StepDto do
    alias Workflow.{Step, Trigger, Filter, Delay, Action}

    @enforce_keys [:id, :title, :description, :type, :trigger, :action, :value]
    defstruct [:id, :title, :description, :type, :trigger, :action, :value]

    @type t :: %__MODULE__{
            id: binary,
            title: binary,
            description: binary,
            type: binary,
            trigger: binary,
            action: binary,
            value: map
          }

    def to_domain(%__MODULE__{} = step_dto) do
      with {:ok, step} <- build_step(step_dto) do
        {:ok,
         %Step{
           id: step_dto.id,
           title: step_dto.title,
           description: step_dto.description,
           step: step
         }}
      end
    end

    defp build_step(%__MODULE__{id: id, type: "trigger", trigger: trigger, value: value}) do
      Trigger.new(id, trigger, value)
    end

    defp build_step(%__MODULE__{id: id, type: "filter", value: value}) do
      Filter.new(id, value)
    end

    defp build_step(%__MODULE__{id: id, type: "delay", value: value}) do
      Delay.new(id, value)
    end

    defp build_step(%__MODULE__{id: id, type: "action", action: action, value: value}) do
      Action.new(id, action, value)
    end
  end

  defmodule ScenarioDto do
    alias Workflow.{Scenario}

    defstruct [:id, :workspace_id, :enabled, :title, :trigger, :ordered_action_ids, :steps]

    @type t :: %__MODULE__{
            id: binary,
            workspace_id: binary,
            enabled: boolean,
            title: binary,
            trigger: binary,
            ordered_action_ids: [StepDto.id()],
            steps: [StepDto.t()]
          }

    def to_domain(%__MODULE__{} = scenario_dto) do
      steps =
        scenario_dto.steps
        |> Enum.map(&StepDto.to_domain/1)
        |> Enum.reduce({:ok, []}, fn
          {:ok, step}, {:ok, steps} -> {:ok, [step | steps]}
          {:error, error}, _ -> {:error, error}
        end)

      %Scenario{
        id: scenario_dto.id,
        workspace_id: scenario_dto.workspace_id,
        enabled: scenario_dto.enabled,
        title: scenario_dto.title,
        trigger_id: scenario_dto.trigger,
        ordered_action_ids: scenario_dto.ordered_action_ids,
        steps: steps
      }
    end
  end
end
