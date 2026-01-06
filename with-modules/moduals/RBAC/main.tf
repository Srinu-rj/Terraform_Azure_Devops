locals {
  iam_role_definition_name="rj_role_iam"
}
#TODO -> 2. Get the current Subscription data
data "azurerm_subscription" "primary_subscription" {}
data "azurerm_client_config" "client_config" {}

# TODO -> AZ CLI TO KNOW LIST OF COMPUTE -> az provider list --query "[].{Provider:namespace, Status:registrationState}" --out table

resource "random_id" "iam_random" {
  byte_length = 4
}

#TODO -> Generate the random password
resource "random_password" "user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

#TODO -> 1. Create the User in Azure AD (Entra ID)
resource "azuread_user" "sri_user" {
  display_name        = "iamuser${lower(random_id.iam_random.hex)}"
  user_principal_name = data.azurerm_client_config.client_config.object_id
  password            = random_password.user_password.result
  mail_nickname       = "raju${random_id.iam_random.hex}"

  # Force user to change password on first login
  force_password_change = true
}

# TODO -> TYPE OF ROLE DEFINITION TO CREATE::
#  Custom Role & Service Principal |
#  Custom Role & User |
#  Custom Role & Management Group |
#  ABAC Condition |

resource "azurerm_role_definition" "iam_role_definition" {
  name  = local.iam_role_definition_name
  scope = data.azurerm_subscription.primary_subscription.id

  # TODO -> The permissions block within the resource is required and includes two main components:[ actions and not_actions ]:
  # TODO -> [actions] -> Microsoft.Resources/subscriptions/resourceGroups/read [only read permission]
  # TODO -> [not_actions] -> Microsoft.Resources/subscriptions/resourceGroups/write [excluding write permission]
  permissions {
    # [only read permission]
    actions = [
      "Microsoft.OperationalInsights/workspaces/search/action",
      "Microsoft.Portal/*",
      "Microsoft.Migrate/*write",
      "Microsoft.Kubernetes",
      "Microsoft.KubernetesRuntime/*",
      "Microsoft.Datadog/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read"

    ]
    # [write permission]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_subscription.primary_subscription.id,
  ]
}

#TODO -> 3. Assign the "Virtual Machine Contributor" role to the user
#TODO -> The scope attribute determines where the permissions apply. Azure follows an inheritance model where permissions at a higher level flow down to the lower levels.
#TODO -> scope-> [Subscription ,Resource Group, Specific Resource]
resource "azurerm_role_assignment" "user_admin_role" {
  principal_id       = azuread_user.sri_user.id
  scope              = data.azurerm_subscription.primary_subscription.id
  role_definition_id = azurerm_role_definition.iam_role_definition.id
}

