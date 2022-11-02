defmodule Workflow do
  defmodule Trigger do
    @enforce_keys [:id, :trigger, :context]
    defstruct [:id, :trigger, :context]

    @type trigger :: :check_in | :cancel_appointment
    @type t :: %__MODULE__{id: binary, trigger: trigger, context: map}
  end

  defmodule Filter do
    alias Workflow.TypedConditions

    @enforce_keys [:id, :conditions]
    defstruct [:id, :conditions]
    @type t :: %__MODULE__{id: binary, conditions: TypedConditions.t()}
  end

  defmodule Delay do
    @enforce_keys [:id, :delay_value, :delay_unit]
    defstruct [:id, :delay_value, :delay_unit]

    @type delay_unit :: :days | :hours | :minutes | :seconds
    @type t :: %__MODULE__{id: binary, delay_value: integer, delay_unit: delay_unit}
  end

  defmodule Action do
    defmodule SendSms do
      @enforce_keys [:phone_number, :text]
      defstruct [:phone_number, :text]

      @type t :: %__MODULE__{phone_number: binary, text: binary}
    end

    @enforce_keys [:id, :action]
    defstruct [:id, :action]
    @type t :: %__MODULE__{id: binary, action: SendSms.t()}
  end

  defmodule RunnableAction do
    defstruct [:filters, :delays, :action]

    @type t :: %__MODULE__{
            filters: [Filter.t()],
            delays: [Delay.t()],
            action: Action.t()
          }
  end

  defmodule StepDto do
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
  end

  defmodule Step do
    defstruct [:id, :title, :description, :step]
    @type id :: binary
    @type step :: Trigger.t() | Filter.t() | Delay.t() | Action.t()
    @type t :: %__MODULE__{id: id, title: binary, description: binary, step: step}
  end

  defmodule Scenario do
    defstruct [:id, :workspace_id, :enabled, :title, :trigger_id, :ordered_action_ids, :steps]

    @type t :: %__MODULE__{
            id: binary,
            workspace_id: binary,
            enabled: boolean,
            title: binary,
            trigger_id: Trigger.trigger(),
            ordered_action_ids: [Step.id()],
            steps: [Step.t()]
          }
  end

  defmodule RunnableScenario do
    defstruct [:id, :workspace_id, :title, :trigger, :actions]

    @type t :: %__MODULE__{
            id: binary,
            workspace_id: binary,
            title: binary,
            trigger: Trigger.t(),
            actions: [RunnableAction.t()]
          }
  end

  @spec compile_scenario(Scenario.t()) :: RunnableScenario.t()
  def compile_scenario(%Scenario{} = scenario) do
    %RunnableScenario{
      id: scenario.id,
      workspace_id: scenario.workspace_id,
      title: scenario.title,
      trigger: compile_trigger(scenario.trigger_id, scenario.steps),
      actions: compile_actions(scenario.ordered_action_ids, scenario.steps)
    }
  end

  @spec compile_trigger(Trigger.trigger(), [Step.t()]) :: Trigger.t()
  defp compile_trigger(trigger_id, steps) do
    steps
    |> Enum.find(&(&1.id == trigger_id))
    |> build_trigger_from_step()
  end

  @spec build_trigger_from_step(Step.t()) :: Trigger.t()
  defp build_trigger_from_step(%Step{step: %Trigger{}} = step) do
    %Trigger{id: step.id, trigger: step.step.trigger, context: step.step.context}
  end

  @spec compile_actions([Step.id()], [Step.t()]) :: [RunnableAction.t()]
  defp compile_actions(step_ids, steps) do
    steps =
      step_ids
      |> Enum.map(& Enum.find(steps, fn step -> &1 == step.id end))

    # Find action steps
    action_steps =
      steps
      |> Enum.filter(&(&1.step.__struct__ == Action))

    action_steps
    |> Enum.map(fn action_step -> 
      index = Enum.find_index(steps, fn step -> step.id == action_step.id end)
      # Find filter steps before action step
      filter_steps =
        steps
        |> Enum.take(index)
        |> Enum.filter(&(&1.step.__struct__ == Filter))

      # Find delay steps before action step
      delay_steps =
        steps
        |> Enum.take(index)
        |> Enum.filter(&(&1.step.__struct__ == Delay))

      %RunnableAction{
        filters: filter_steps |> Enum.map(& &1.step),
        delays: delay_steps |> Enum.map(& &1.step),
        action: action_step.step
      }
    end)
  end
end
