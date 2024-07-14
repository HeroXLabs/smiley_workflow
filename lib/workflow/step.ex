defmodule Workflow.Step do
  alias Workflow.{Action, Delay, Filter, Trigger}

  @enforce_keys [:id, :scenario_id, :title, :description, :step]
  defstruct [:id, :scenario_id, :title, :description, :step, context: %{}]

  @type id :: binary
  @type step :: Trigger.t() | Filter.t() | Delay.t() | Action.t()
  @type t :: %__MODULE__{id: id, title: binary, description: binary, step: step}

  def is_action_step?(%__MODULE__{step: %Action.SendSms{}}), do: true
  def is_action_step?(%__MODULE__{step: %Action.SendCoupon{}}), do: true
  def is_action_step?(_), do: false

  def is_trigger_step?(%__MODULE__{step: %Trigger{}}), do: true
  def is_trigger_step?(_), do: false

  def is_delay_step?(%__MODULE__{step: %Delay{}}), do: true
  def is_delay_step?(_), do: false

  def is_filter_step?(%__MODULE__{step: %Filter{}}), do: true
  def is_filter_step?(_), do: false

  def is_incomplete_step?(%__MODULE__{step: %Action.Incomplete{}}), do: true
  def is_incomplete_step?(%__MODULE__{step: %Filter.Incomplete{}}), do: true
  def is_incomplete_step?(%__MODULE__{step: %Delay.Incomplete{}}), do: true
  def is_incomplete_step?(_), do: false
end
