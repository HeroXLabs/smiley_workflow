defmodule Workflow.NewTrigger do
  alias Workflow.Trigger.TriggerType

  defstruct [:title, :description, :trigger, :context]

  @type t :: %__MODULE__{
          title: binary,
          description: binary,
          trigger: TriggerType.t(),
          context: map
        }

  def new(title, descrption, trigger, context) do
    {:ok, trigger_type} = TriggerType.new(trigger)
    %__MODULE__{title: title, description: descrption, trigger: trigger_type, context: context}
  end
end
