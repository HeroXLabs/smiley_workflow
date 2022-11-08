defmodule Workflow.StepUpdate do
  alias Workflow.{Step, Filter, Delay, Action, TypedConditions, Template}

  defmodule ReplaceStep do
    @enforce_keys [:id, :template_step_id]
    defstruct [:id, :template_step_id]
  end

  defmodule UpdateStep do
    @enforce_keys [:id, :value]
    defstruct [:id, :value]
  end

  defmodule UpdateFilterStep do
    @enforce_keys [:step, :conditions]
    defstruct [:step, :conditions]

    @type t :: %__MODULE__{
      step: Step.t(),
      conditions: TypedConditions.t()
    }

    def new(step, %{"conditions" => raw_conditions}) do
      with {:ok, conditions} <- TypedConditions.parse_conditions(raw_conditions, &Template.conditions_mapping/1) do
        {:ok, %__MODULE__{step: step, conditions: conditions}}
      end
    end
  end

  defmodule UpdateDelayStep do
    defstruct [:step, :delay_value, :delay_unit]

    @type t :: %__MODULE__{
      step: Step.t(),
      delay_value: integer,
      delay_unit: Delay.delay_unit()
    }

    def new(step, %{"delay_value" => delay_value, "delay_unit" => delay_unit}) do
      {:ok, %__MODULE__{step: step, delay_value: delay_value, delay_unit: delay_unit}}
    end
  end

  defmodule UpdateActionStep do
    defstruct [:step, :value]

    @type t :: %__MODULE__{
      step: Step.t(),
      value: map
    }

    def new(step, value) do
      # TODO: validate if value matches step
      {:ok, %__MODULE__{step: step, value: value}}
    end
  end

  def new(%{"id" => id} = params, repository) do
    case Map.get(params, "template_step_id") do
      nil ->
        value = Map.get(params, "value")
        with {:ok, step} <- repository.get_step(id) do
          case step do
            %Step{step: %Filter{}} ->
              UpdateFilterStep.new(step, value)
            %Step{step: %Delay{}} ->
              UpdateDelayStep.new(step, value)
            %Step{step: %Action.SendSms{}} ->
              UpdateActionStep.new(step, value)
          end
        end
      template_step_id -> 
        {:ok, %ReplaceStep{id: id, template_step_id: template_step_id}}
    end
  end
end
