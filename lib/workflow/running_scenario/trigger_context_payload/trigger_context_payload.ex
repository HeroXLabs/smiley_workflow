defmodule Workflow.RunningScenario.TriggerContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{
    CheckInContextPayload,
    CheckOutContextPayload,
    CancelAppointmentContextPayload,
    NewPaidMembershipContextPayload,
    FormResponseContextPayload
  }

  @type t ::
          CheckInContextPayload.t()
          | CheckOutContextPayload.t()
          | CancelAppointmentContextPayload.t()
          | NewPaidMembershipContextPayload.t()
          | FormResponseContextPayload.t()
end
