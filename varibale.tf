variable "cidr_block" {
    default = "10.0.0.0/16"
}

variable "ami_id" {
    default = "ami-080e1f13689e07408"
  
}

# Backend Variables
variable "state_bucket_name" {
    default = "tfproject-state-bucket"
}

variable "state_table_name" {
    default = "tf-demo-state-table"
}

variable "aws_region" {
    default = "us-east-1"
}