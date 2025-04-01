variable "upstream_dns_servers" {
  type        = list(string)
  description = "List of upstream DNS servers for forwarding"
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "allow_remote_requests" {
  type        = bool
  description = "Whether to allow DNS requests from remote networks"
  default     = false
}

variable "cache_size" {
  type        = number
  description = "Size of DNS cache in KiB"
  default     = 2048
}