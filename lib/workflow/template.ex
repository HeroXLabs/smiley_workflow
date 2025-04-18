defmodule Workflow.Template do
  defmodule TriggerTemplate do
    @derive Jason.Encoder
    @enforce_keys [:id, :title, :description, :type, :trigger, :context]
    defstruct [:id, :title, :description, :type, :trigger, :context]
  end

  defmodule ActionTemplate do
    @derive Jason.Encoder
    @enforce_keys [:id, :title, :description, :type, :action, :context]
    defstruct [:id, :title, :description, :type, :action, :context]
  end

  @conditions_map %{
    "phone_number" => :string,
    "first_name" => :string,
    "tags" => :selection,
    "visits_count" => :number,
    "last_visit_at" => :date,
    "check_in.services" => :selection,
    "check_out.services" => :selection,
    "check_out.service_categories" => :selection,
    "check_out.stars_earned" => :number,
    "appointment.start_at" => :date,
    "appointment.services" => :selection,
    "employees.phone_number" => :string,
    "employees.first_name" => :string,
    "coupon.expire_date" => :date,
    "has_upcoming_appointments" => :boolean
  }

  def triggers() do
    [
      %TriggerTemplate{
        id: "step-check-in",
        title: "User checks in",
        description: "Trigger when a user checks in",
        type: "trigger",
        trigger: "check_in",
        context: %{
          "customer" => [
            %{id: "phone_number", name: "Customer phone number", category: "string"},
            %{id: "first_name", name: "Customer first name", category: "string"},
            %{id: "tags", name: "Customer tags", category: "array"},
            %{id: "visits_count", name: "Number of visits", category: "number"},
            %{id: "last_visit_at", name: "Last visit date", category: "date"},
            %{
              id: "has_upcoming_appointments",
              name: "Has upcoming appointments",
              category: "boolean"
            }
          ],
          "business" => [
            %{id: "name", name: "Business name", category: "string"}
          ],
          "check_in" => [
            %{id: "services", name: "Check-in services", category: "selection"}
          ]
        }
      },
      %TriggerTemplate{
        id: "step-check-out",
        title: "User checks out",
        description: "Trigger when a user checks out",
        type: "trigger",
        trigger: "check_out",
        context: %{
          "customer" => [
            %{id: "phone_number", name: "Customer phone number", category: "string"},
            %{id: "first_name", name: "Customer first name", category: "string"},
            %{id: "tags", name: "Customer tags", category: "array"},
            %{id: "visits_count", name: "Number of visits", category: "number"},
            %{id: "last_visit_at", name: "Last visit date", category: "date"},
            %{
              id: "has_upcoming_appointments",
              name: "Has upcoming appointments",
              category: "boolean"
            }
          ],
          "business" => [
            %{id: "name", name: "Business name", category: "string"}
          ],
          "check_out" => [
            %{id: "services", name: "Check-in services", category: "selection"},
            %{
              id: "service_categories",
              name: "Check-in service categories",
              category: "selection"
            },
            %{id: "stars_earned", name: "Points earned", category: "number"}
          ]
        }
      },
      %TriggerTemplate{
        id: "step-cancel-appointment",
        title: "Cancel appointment",
        description: "Trigger when a user cancels an appointment",
        type: "trigger",
        trigger: "cancel_appointment",
        context: %{
          "customer" => [
            %{id: "phone_number", name: "Customer phone number", category: "string"},
            %{
              id: "masked_phone_number",
              name: "Masked customer phone number",
              category: "string"
            },
            %{id: "first_name", name: "Customer first name", category: "string"},
            %{id: "tags", name: "Customer tags", category: "array"},
            %{id: "visits_count", name: "Number of visits", category: "number"},
            %{id: "last_visit_at", name: "Last visit date", category: "date"},
            %{
              id: "has_upcoming_appointments",
              name: "Has upcoming appointments",
              category: "boolean"
            }
          ],
          "business" => [
            %{id: "name", name: "Business name", category: "string"}
          ],
          "appointment" => [
            %{id: "start_at", name: "Appointment start at", category: "date"},
            %{id: "services", name: "Appointment services", category: "selection"},
            %{id: "employees", name: "Appointment assignees", category: "selection"}
          ],
          "employee_1" => [
            %{id: "phone_number", name: "Employee phone number", category: "string"},
            %{id: "first_name", name: "Employee first name", category: "string"}
          ]
        }
      },
      %TriggerTemplate{
        id: "step-new-paid-membership",
        title: "New paid membership",
        description: "Trigger when a new paid membership is created",
        type: "trigger",
        trigger: "new_paid_membership",
        context: %{
          "customer" => [
            %{id: "phone_number", name: "Customer phone number", category: "string"},
            %{
              id: "masked_phone_number",
              name: "Masked customer phone number",
              category: "string"
            },
            %{id: "first_name", name: "Customer first name", category: "string"},
            %{id: "tags", name: "Customer tags", category: "array"},
            %{id: "visits_count", name: "Number of visits", category: "number"},
            %{id: "last_visit_at", name: "Last visit date", category: "date"},
            %{
              id: "has_upcoming_appointments",
              name: "Has upcoming appointments",
              category: "boolean"
            }
          ],
          "business" => [
            %{id: "name", name: "Business name", category: "string"}
          ],
          "membership" => [
            %{id: "id", name: "Membership ID", category: "string"},
            %{id: "title", name: "Membership title", category: "string"},
            %{id: "price", name: "Membership price", category: "number"},
            %{id: "plan_frequency", name: "Membership plan type", category: "string"}
          ]
        }
      }
    ]
  end

  def actions() do
    [
      %ActionTemplate{
        id: "step-filter",
        title: "Continue only if",
        description: "Continue only if the condition is met",
        type: "action",
        action: "filter",
        context: %{}
      },
      %ActionTemplate{
        id: "step-delay",
        title: "Delay for",
        description: "Delay the workflow for a given amount of time",
        type: "action",
        action: "delay",
        context: %{}
      },
      %ActionTemplate{
        id: "step-schedule-text",
        title: "Send a text message",
        description: "Send a text message to a customer",
        type: "action",
        action: "send_sms",
        context: %{}
      },
      %ActionTemplate{
        id: "step-schedule-coupon",
        title: "Send a coupon",
        description: "Send a coupon to a customer",
        type: "action",
        action: "send_coupon",
        context: %{
          "coupon" => [
            %{id: "title", name: "Coupon title", category: "string"},
            %{id: "link", name: "Coupon link", category: "string"},
            %{id: "expire_date", name: "Coupon expire date", category: "date"}
          ]
        }
      },
      %ActionTemplate{
        id: "step-reward-star",
        title: "Reward star balance",
        description: "Reward stars to a customer",
        type: "action",
        action: "reward_star",
        context: %{}
      },
      %ActionTemplate{
        id: "step-add-stamp",
        title: "Add stamp",
        description: "Add stamps to a customer",
        type: "action",
        action: "add_stamp",
        context: %{}
      }
    ]
  end

  def conditions_mapping(key) do
    Map.get(@conditions_map, key, :string)
  end

  def find_trigger(template_trigger_id) do
    triggers()
    |> Enum.find(fn %TriggerTemplate{id: id} -> id == template_trigger_id end)
  end

  def find_action(template_action_id) do
    actions()
    |> Enum.find(fn %ActionTemplate{id: id} -> id == template_action_id end)
  end
end
