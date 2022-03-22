variable "description" {
  type        = string
  description = ""
  default     = "A KMS key used to encrypt objects at rest stored in AWS S3."
}

variable "enable_key_rotation" {
  type        = bool
  description = "Specifies whether key rotation is enabled."
  default     = true
}

variable "key_deletion_window_in_days" {
  type        = string
  description = "Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days."
  default     = 30
}

variable "name" {
  type        = string
  description = "The display name of the alias. The name must start with the word \"alias\" followed by a forward slash (alias/)."
  default     = "alias/s3"
}

variable "principals_extended" {
  type = list(object({
    identifiers = list(string)
    type        = string
  }))
  default     = []
  description = "extended for support of AWS principals that do not use the AWS identifier"
}
variable "principals" {
  type        = list(string)
  description = "AWS Principals that can use this KMS key.  Use [\"*\"] to allow all principals."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the KMS key."
  default     = {}
}
