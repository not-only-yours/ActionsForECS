variable "aws_region" {
  description = "The AWS region to create things in."
  # Ireland
  default     = "eu-west-2"
}
# Use the command line to inject this variable
variable "personal_access_token"{
  description = "personal token"
  default = "replace_this_with_your_token"
}