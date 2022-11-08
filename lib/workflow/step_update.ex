defmodule Workflow.StepUpdate do
  alias Workflow.{Step, Filter, Delay, Action}

  defmodule ReplaceStep do
    @enforce_keys [:step, :template_step_id]
    defstruct [:step, :template_step_id]
  end

  defmodule UpdateStep do
    @enforce_keys [:step, :update]
    defstruct [:step, :update]
  end

  @type t :: ReplaceStep.t() | UpdateStep.t()

  defmodule UpdateFilter do
    alias Workflow.Filter

    @enforce_keys [:filter]
    defstruct [:filter]

    @type t :: %__MODULE__{
            filter: Filter.t()
          }

    def new(value) do
      case Filter.new(value) do
        {:ok, %Filter{} = filter} ->
          {:ok, %__MODULE__{filter: filter}}

        _ ->
          {:error, "Invalid filter value"}
      end
    end
  end

  defmodule UpdateDelay do
    alias Workflow.Delay

    @enforce_keys [:delay]
    defstruct [:delay]

    @type t :: %__MODULE__{
            delay: Delay.t()
          }

    def new(value) do
      case Delay.new(value) do
        {:ok, %Delay{} = delay} ->
          {:ok, %__MODULE__{delay: delay}}

        _ ->
          {:error, "Invalid delay value"}
      end
    end
  end

  defmodule UpdateAction do
    alias Workflow.Action

    @enforce_keys [:action]
    defstruct [:action]

    @type t :: %__MODULE__{
            action: Action.t()
          }

    def new(action_name, value) do
      case Action.new(action_name, value) do
        {:ok, %Action.SendSms{} = action} ->
          {:ok, %__MODULE__{action: action}}

        _ ->
          {:error, "Invalid action value"}
      end
    end
  end

  def new(%{"id" => id} = params, repository) do
    case Map.get(params, "template_step_id") do
      nil ->
        value = Map.get(params, "value")

        with {:ok, step} <- repository.get_step(id),
             {:ok, update} <- build_update(step, value) do
          {:ok, %UpdateStep{step: step, update: update}}
        end

      template_step_id ->
        with {:ok, step} <- repository.get_step(id) do
          {:ok, %ReplaceStep{step: step, template_step_id: template_step_id}}
        end
    end
  end

  defp build_update(step, value) do
    case step do
      %Step{step: %Filter{}} ->
        UpdateFilter.new(value)

      %Step{step: %Delay{}} ->
        UpdateDelay.new(value)

      %Step{step: %Action.SendSms{}} ->
        UpdateAction.new(step.action, value)
    end
  end
end
