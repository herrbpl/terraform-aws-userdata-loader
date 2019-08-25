variable "aws_region" {
  type = "string"
  default = "eu-central-1"
}
variable "name" {
    description = "Environment name, used as bucket prefix"
    default     = "bootscripts"
}

variable "bucket" {
    description = "Existing bucket name, if empty, new one will be created"
    default = ""
}

variable "logging_bucket" {
    description = "Bucket to use for logging"
    default = ""
}

variable "local_exec_interpreter" {
  description = "Command to run for local-exec resources. Must be a shell-style interpreter. If you are on Windows Git Bash is a good choice."
  type        = list(string)
  default     = ["/bin/sh", "-c"]
}

variable "cache_path" {
    description = "Cache location"
    default = ""
}

variable "cleanup_cloudinit" {
    description = "Clean up cloudinit files? Tested only on Ubuntu. NB! Use string literal with quotes true to enable"
    default = "false"
}

variable "scripts" {
  type = list(object({
    name            = string
    filename        = string
    template        = string
    vars            = map(string)
  }))

  default = [
    {
        name = "default",
        filename = "default"
        template = "default.tpl",
        vars = {}    
    }
  ]
}