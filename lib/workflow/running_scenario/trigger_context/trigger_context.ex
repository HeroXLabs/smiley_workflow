defmodule Workflow.RunningScenario.TriggerContext do
  @derive Jason.Encoder
  @enforce_keys [:workspace_id, :trigger_type, :context]
  defstruct [:workspace_id, :trigger_type, :context]

  alias Workflow.Trigger.TriggerType

  alias __MODULE__.{
    CheckInContext,
    CheckOutContext,
    CancelAppointmentContext,
    NewPaidMembershipContext
  }

  @type t :: %__MODULE__{
          workspace_id: binary,
          trigger_type: TriggerType.t(),
          context:
            CheckInContext.t()
            | CheckOutContext.t()
            | CancelAppointmentContext.t()
            | NewPaidMembershipContext.t()
        }

  def from_json(%{
        "workspace_id" => workspace_id,
        "trigger_type" => trigger_type,
        "context" => context
      }) do
    with {:ok, trigger_type} <- TriggerType.new(trigger_type),
         {:ok, context} <- context_from_json(context) do
      {:ok, %__MODULE__{workspace_id: workspace_id, trigger_type: trigger_type, context: context}}
    end
  end

  defp context_from_json(%{
         "type" => "check_in",
         "customer_id" => customer_id,
         "check_in_id" => check_in_id
       }) do
    {:ok,
     %CheckInContext{
       customer_id: customer_id,
       check_in_id: check_in_id
     }}
  end

  defp context_from_json(%{
         "type" => "check_out",
         "customer_id" => customer_id,
         "check_out_id" => check_out_id
       }) do
    {:ok,
     %CheckOutContext{
       customer_id: customer_id,
       check_out_id: check_out_id
     }}
  end

  defp context_from_json(%{
         "type" => "cancel_appointment",
         "customer_id" => customer_id,
         "appointment_id" => appointment_id
       }) do
    {:ok,
     %CancelAppointmentContext{
       customer_id: customer_id,
       appointment_id: appointment_id
     }}
  end

  defp context_from_json(%{
         "type" => "new_paid_membership",
         "customer_id" => customer_id,
         "membership_id" => membership_id,
         "membership_plan_id" => membership_plan_id
       }) do
    {:ok,
     %NewPaidMembershipContext{
       customer_id: customer_id,
       membership_id: membership_id,
       membership_plan_id: membership_plan_id
     }}
  end

  defp context_from_json(_) do
    {:error, "Invalid trigger context json payload"}
  end
end
