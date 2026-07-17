variable "ca_crt_ttl" {
  description = "validity of ca crt in hours"
  type        = number
  default     = 865200 # ten years
}

variable "ca_cn" {
  description = "common name for ca crt"
  type        = string
  default     = "kubernetes"
}

variable "client_crt_ttl" {
  description = "validity of client crt in hours"
  type        = number
  default     = 86520 # one year
}
