variable "host_os" {
  type = string
}

variable "env_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_rg" {
  type = string
}

variable "key_vault_username_field_name" {
  type    = string
  default = "jenkins-username"
}

variable "key_vault_password_field_name" {
  type    = string
  default = "jenkins-password"
}