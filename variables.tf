variable "environment" {
  type        = string
  description = "The shorthand id name of the deployment environment, ie. prod, qa"
}

variable "location" {
  type        = string
  description = "The Azure region to deploy to."
  default     = "centralus"
}

variable "region" {
  type        = string
  description = "The determined shorthand for the Azure region, used in naming schema."
  default     = "cus"
}

variable "business_unit_short" {
  type        = string
  description = "The buisness unit short id used in naming."
  default     = "cd"
}

variable "business_unit" {
  type        = string
  description = "The buisness unit used in naming."
  default     = "custom-development"
}

variable "tags" {
  type        = map(any)
  description = "The azure tags to add to the resources."
  default     = {}
}

variable "vnet_mask" {
  type        = number
  description = "The CIDR mask, ie. /21, that determines the size of the vnet address spacing."
  default     = 21
  validation {
    condition     = var.cidr_mask >= 0 && var.cidr_mask <= 32
    error_message = "The CIDR mask must be between 0 and 32."
  }
}
