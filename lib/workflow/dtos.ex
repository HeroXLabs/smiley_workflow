defmodule Workflow.Dto do
  defmodule NewStepDto do
    @derive Jason.Encoder
    @enforce_keys [:title, :description, :type, :trigger, :action, :value, :context]
    defstruct [:title, :description, :type, :trigger, :action, :value, :context]

    @type t :: %__MODULE__{
            title: binary,
            description: binary,
            type: binary,
            trigger: binary | nil,
            action: binary | nil,
            value: map | nil,
            context: map | nil
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
            trigger: to_string(new_scenario.trigger.trigger),
            action: nil,
            context: new_scenario.trigger.context,
            value: nil
          }
        ]
      }
    end
  end

  defmodule StepDto do
    alias Workflow.{Step, Trigger, Filter, Delay, Action}

    @derive Jason.Encoder
    @enforce_keys [
      :id,
      :scenario_id,
      :title,
      :description,
      :type,
      :trigger,
      :action,
      :context,
      :value
    ]
    defstruct [
      :id,
      :scenario_id,
      :title,
      :description,
      :type,
      :trigger,
      :action,
      :context,
      :value
    ]

    @type t :: %__MODULE__{
            id: binary,
            scenario_id: binary,
            title: binary,
            description: binary | nil,
            type: binary,
            trigger: binary | nil,
            action: binary | nil,
            context: map | nil,
            value: map | nil
          }

    def to_domain(%__MODULE__{} = step_dto) do
      with {:ok, step} <- build_step(step_dto) do
        {:ok,
         %Step{
           id: step_dto.id,
           scenario_id: step_dto.scenario_id,
           title: step_dto.title,
           description: step_dto.description,
           step: step
         }}
      end
    end

    def from_domain(%Step{} = step) do
      %__MODULE__{
        id: step.id,
        scenario_id: step.scenario_id,
        title: step.title,
        description: step.description,
        type: build_type(step.step),
        trigger: build_trigger(step.step),
        action: build_action(step.step),
        context: build_context(step.step),
        value: build_value(step.step)
      }
    end

    defp build_type(%Trigger{}), do: "trigger"
    defp build_type(_), do: "action"

    defp build_trigger(%Trigger{} = trigger), do: to_string(trigger.type)
    defp build_trigger(_), do: nil

    defp build_action(%Trigger{}), do: nil
    defp build_action(%Filter{}), do: "filter"
    defp build_action(%Filter.Incomplete{}), do: "filter"
    defp build_action(%Delay{}), do: "delay"
    defp build_action(%Delay.Incomplete{}), do: "delay"
    defp build_action(%Action.SendSms{}), do: "send_sms"
    defp build_action(%Action.SendCoupon{}), do: "send_coupon"
    defp build_action(%Action.Incomplete{action: action}), do: to_string(action)

    defp build_context(%Trigger{} = trigger), do: trigger.context
    defp build_context(_), do: nil

    defp build_value(%Trigger{}), do: nil
    defp build_value(%Filter{} = filter), do: %{"conditions" => filter.raw_conditions}

    defp build_value(%Delay{} = delay),
      do: %{"delay_value" => delay.delay_value, "delay_unit" => to_string(delay.delay_unit)}

    defp build_value(step), do: Map.from_struct(step)

    defp build_step(%__MODULE__{type: "trigger", trigger: trigger, context: context}) do
      Trigger.new(trigger, context)
    end

    defp build_step(%__MODULE__{type: "action", action: "delay", value: value}) do
      Delay.new(value)
    end

    defp build_step(%__MODULE__{type: "action", action: "filter", value: value}) do
      Filter.new(value)
    end

    defp build_step(%__MODULE__{type: "action", action: action, value: value}) do
      Action.new(action, value)
    end
  end

  defmodule ScenarioDto do
    alias Workflow.{Scenario, Step}

    @enforce_keys [:id, :workspace_id, :enabled, :title, :ordered_action_ids, :steps]
    defstruct [:id, :workspace_id, :enabled, :title, :ordered_action_ids, :steps]

    @type t :: %__MODULE__{
            id: binary,
            workspace_id: binary,
            enabled: boolean,
            title: binary,
            ordered_action_ids: [Step.id()],
            steps: [StepDto.t()]
          }

    def to_domain(%__MODULE__{} = scenario_dto) do
      with {:ok, steps} <-
             scenario_dto.steps
             |> Enum.map(&StepDto.to_domain/1)
             |> Enum.reduce({:ok, []}, fn
               {:ok, step}, {:ok, steps} -> {:ok, [step | steps]}
               {:error, error}, _ -> {:error, error}
             end) do
        trigger_step =
          steps
          |> Enum.find(fn step -> Step.is_trigger_step?(step) end)

        if is_nil(trigger_step) do
          {:error, "Scenario must have a trigger step"}
        else
          {:ok,
           %Scenario{
             id: scenario_dto.id,
             workspace_id: scenario_dto.workspace_id,
             enabled: scenario_dto.enabled,
             title: scenario_dto.title,
             trigger_id: trigger_step.id,
             ordered_action_ids: scenario_dto.ordered_action_ids,
             steps: steps
           }}
        end
      end
    end
  end
end
