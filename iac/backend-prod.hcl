bucket         = "ops-solution-tearrform-state"
key            = "prod/terraform.tfstate"
region         = "ap-southeast-1"
encrypt        = true
dynamodb_table = "ops-solution-terraform-locks"

