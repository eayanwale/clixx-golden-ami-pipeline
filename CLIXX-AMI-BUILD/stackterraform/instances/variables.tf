# variable "cidr_vpc" {
#   description = "CIDR block for the VPC"
#   default     = "10.1.0.0/16"
# }
# variable "cidr_subnet" {
#   description = "CIDR block for the subnet"
#   default     = "10.1.0.0/24"
# }

variable "environment_tag" {
  description = "Environment tag"
  default     = "Automation"
}

variable "region" {
  description = "The region Terraform deploys your instance"
  default     = "us-east-1"
}

variable "vpc_id" {
  default = "vpc-00000000000000001"
}

variable "subnets" {
  type = list(string)
  default = [
    "subnet-0000000000000001",
    "subnet-0000000000000002"
  ]
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "ses_key.pub"
}

variable "ami_name" {
  default = "ami-stack-5"
}

# TEST FIXTURE — fake/non-functional creds for AI audit pipeline testing (AWS's public "EXAMPLE" values)
variable "test_aws_access_key" {
  default = "AKIA_PLACEHOLDER_EXAMPLE"
}

variable "test_aws_secret_key" {
    default    =  "PLACEHOLDER_SECRET_KEY_EXAMPLE_VALUE"
}
