# variables.tf

variable "aws_region" {
  description = "The AWS region where the EKS cluster will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name for your EKS cluster."
  type        = string
  default     = "my-practice-eks-cluster"
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.28" # Choose a supported version
}

variable "instance_type" {
  description = "The EC2 instance type for the EKS worker nodes."
  type        = string
  default     = "t3.medium" # Consider t2.medium or t3.small for cheaper practice
}

variable "desired_capacity" {
  description = "The desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "The maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "The minimum number of worker nodes."
  type        = number
  default     = 1
}