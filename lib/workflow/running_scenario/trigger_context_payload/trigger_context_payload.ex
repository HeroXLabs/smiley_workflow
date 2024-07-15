defmodule Workflow.RunningScenario.TriggerContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{CheckInContextPayload, CheckOutContextPayload, CancelAppointmentContextPayload, NewPaidMembershipContextPayload}

  @type t ::
          CheckInContextPayload.t()
          | CheckOutContextPayload.t()
          | CancelAppointmentContextPayload.t()
          | NewPaidMembershipContextPayload.t()
end
