# The Canonical User ID data source allows access to the canonical user ID for the effective account in which Terraform is working.
# tflint-ignore: terraform_unused_declarations
data "aws_canonical_user_id" "current_user" {
}


# # # rando value for filtering output and validating results
# resource "random_string" "output" {
#   for_each = var.AWS_MACHINE_CONFIGS
#   length   = 6
#   special  = false
# }
