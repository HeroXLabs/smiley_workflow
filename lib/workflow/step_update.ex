defmodule Workflow.StepUpdate do
  alias Workflow.{Step, Filter, Delay, Action}
  alias Workflow.UpdateStepParams

  defmodule ReplaceStep do
    @enforce_keys [:step, :template_step_id]
    defstruct [:step, :template_step_id]
    @type t :: %__MODULE__{step: Step.t(), template_step_id: term}
  end

  defmodule UpdateStep do
    @enforce_keys [:step, :update]
    defstruct [:step, :update]
    @type t :: %__MODULE__{step: Step.t(), update: term}
  end

  @type t :: ReplaceStep.t() | UpdateStep.t()

  defmodule UpdateFilter do
    alias Workflow.Filter

    @enforce_keys [:filter, :value]
    defstruct [:filter, :value]

    @type t :: %__MODULE__{
            filter: Filter.t(),
            value: map
          }

    def new(value) do
      case Filter.new(value) do
        {:ok, %Filter{} = filter} ->
          {:ok, %__MODULE__{filter: filter, value: value}}

        _ ->
          {:error, "Invalid filter value"}
      end
    end
  end

  defmodule UpdateDelay do
    alias Workflow.Delay

    @enforce_keys [:delay, :value]
    defstruct [:delay, :value]

    @type t :: %__MODULE__{
            delay: Delay.t(),
            value: map
          }

    def new(value) do
      case Delay.new(value) do
        {:ok, %Delay{} = delay} ->
          {:ok, %__MODULE__{delay: delay, value: value}}

        _ ->
          {:error, "Invalid delay value"}
      end
    end
  end

  defmodule UpdateAction do
    alias Workflow.Action

    @enforce_keys [:action, :value]
    defstruct [:action, :value]

    @type t :: %__MODULE__{
            action: Action.t(),
            value: map
          }

    def new(action_name, value) do
      case Action.new(action_name, value) do
        {:ok, action} ->
          {:ok, %__MODULE__{action: action, value: value}}

        _ ->
          {:error, "Invalid action value"}
      end
    end
  end

  def new(%Step{} = step, %UpdateStepParams{template_step_id: template_step_id, value: value}) do
    case template_step_id do
      nil ->
        with {:ok, update} <- build_update(step, value) do
          {:ok, %UpdateStep{step: step, update: update}}
        end

      template_step_id ->
        {:ok, %ReplaceStep{step: step, template_step_id: template_step_id}}
    end
  end

  defp build_update(step, value) do
    case step do
      %Step{step: %Filter{}} ->
        UpdateFilter.new(value)

      %Step{step: %Delay{}} ->
        UpdateDelay.new(value)

      %Step{step: %Action.SendSms{}} ->
        UpdateAction.new("send_sms", value)

      %Step{step: %Action.SendCoupon{}} ->
        UpdateAction.new("send_coupon", value)

      %Step{step: %Action.RewardStar{}} ->
        UpdateAction.new("reward_star", value)

      %Step{step: %Action.AddStamp{}} ->
        UpdateAction.new("add_stamp", value)

      %Step{step: %Filter.Incomplete{}} ->
        UpdateFilter.new(value)

      %Step{step: %Delay.Incomplete{}} ->
        UpdateDelay.new(value)

      %Step{step: %Action.Incomplete{action: :send_sms}} ->
        UpdateAction.new("send_sms", value)

      %Step{step: %Action.Incomplete{action: :send_coupon}} ->
        UpdateAction.new("send_coupon", value)

      %Step{step: %Action.Incomplete{action: :reward_star}} ->
        UpdateAction.new("reward_star", value)
    end
  end
end
