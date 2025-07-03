variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "Nom de la clé SSH AWS"
  type        = string
}

variable "security_group_id" {
  description = "ID du security group"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet"
  type        = string
}
