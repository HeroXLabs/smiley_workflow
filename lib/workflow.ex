defmodule Workflow do
  alias __MODULE__.Template

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

      # TODO: support {{appointment.employees.phone_number}} as phone_number
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

  defmodule NewStepDto do
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

  defmodule Step do
    @enforce_keys [:id, :title, :description, :step]
    defstruct [:id, :title, :description, :step]

    @type id :: binary
    @type step :: Trigger.t() | Filter.t() | Delay.t() | Action.t()
    @type t :: %__MODULE__{id: id, title: binary, description: binary, step: step}
  end

  defmodule NewTrigger do
    defstruct [:title, :description, :trigger, :context]

    @type t :: %__MODULE__{title: binary, description: binary, trigger: binary, context: map}
  end

  defmodule NewScenarioParams do
    defstruct [:workspace_id, :template_trigger_id]

    @type t :: %__MODULE__{workspace_id: binary, template_trigger_id: binary}
  end

  defmodule NewScenario do
    defstruct [:workspace_id, :title, :new_trigger]

    @type t :: %__MODULE__{workspace_id: binary, title: binary, new_trigger: NewTrigger.t()}
  end

  defmodule NewStepParams do
    defstruct [:workspace_id, :template_step_id]

    @type t :: %__MODULE__{workspace_id: binary, template_step_id: binary}
  end

  defmodule IncompleteFilter do
    defstruct [:id]

    @type t :: %__MODULE__{id: binary}
  end

  defmodule Scenario do
    defstruct [:id, :workspace_id, :enabled, :title, :trigger_id, :ordered_action_ids, :steps]

    @type id :: binary

    @type t :: %__MODULE__{
            id: id,
            workspace_id: binary,
            enabled: boolean,
            title: binary,
            trigger_id: Trigger.trigger(),
            ordered_action_ids: [Step.id()],
            steps: [Step.t()]
          }
  end

  # TODO: may not need ScenarioDto
  defmodule ScenarioDto do
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
  end

  defmodule NewScenarioDto do
    defstruct [:workspace_id, :title, :trigger, :steps]

    @type t :: %__MODULE__{
            workspace_id: binary,
            title: binary,
            trigger: binary,
            steps: [NewStepDto.t()]
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

  def create_new_scenario(%NewScenarioParams{} = params, repository) do
    params
    |> new_scenario()
    |> to_new_scenario_dto()
    |> repository.create_new_scenario()
  end

  def add_step(%NewStepParams{} = params, repository) do
    step_dto = new_step_dto(params)
    repository.add_step(params.workspace_id, step_dto)
  end

  def new_scenario(%NewScenarioParams{} = params) do
    trigger_template =
      Template.triggers
      |> Enum.find(&(&1.id == params.template_trigger_id))

    if is_nil(trigger_template) do
      raise "Trigger template not found"
    end

    %NewScenario{
      workspace_id: params.workspace_id,
      title: trigger_template.title <> " workflow",
      new_trigger: %NewTrigger{
        title: trigger_template.title,
        description: trigger_template.description,
        trigger: trigger_template.trigger,
        context: trigger_template.context
      }
    }
  end

  def new_step_dto(%NewStepParams{} = params) do
    step_template =
      Template.actions
      |> Enum.find(&(&1.id == params.template_step_id))

    if is_nil(step_template) do
      raise "Step template not found"
    end

    %NewStepDto{
      title: step_template.title,
      description: step_template.description,
      type: "action",
      trigger: nil,
      action: step_template.action,
      value: nil
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

  @spec to_new_scenario_dto(NewScenario.t()) :: NewScenarioDto.t()
  defp to_new_scenario_dto(%NewScenario{} = new_scenario) do
    %NewScenarioDto{
      workspace_id: new_scenario.workspace_id,
      title: new_scenario.title,
      trigger: new_scenario.new_trigger.trigger,
      steps: [
        %NewStepDto{
          title: new_scenario.new_trigger.title,
          description: new_scenario.new_trigger.description,
          type: "trigger",
          trigger: new_scenario.new_trigger.trigger,
          action: nil,
          value: new_scenario.new_trigger.context
        }
      ]
    }
  end
end
