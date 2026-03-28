defmodule Workflow.RunningScenario.WebhookSender do
  alias Workflow.Action.OutgoingWebhook
  alias Workflow.RunningScenario.TriggerContextPayload

  @callback send_webhook(OutgoingWebhook.t(), TriggerContextPayload.t()) :: :ok | {:error, any}
end
