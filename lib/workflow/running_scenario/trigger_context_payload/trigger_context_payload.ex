defmodule Workflow.RunningScenario.TriggerContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{CheckInContextPayload, CheckOutContextPayload, CancelAppointmentContextPayload}

  @type t ::
          CheckInContextPayload.t()
          | CheckOutContextPayload.t()
          | CancelAppointmentContextPayload.t()
end
