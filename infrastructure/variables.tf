variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "devops-minimal"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "ssh_key_name" {
  description = "Nom de la clé SSH AWS pour accéder aux instances"
  type        = string
}
