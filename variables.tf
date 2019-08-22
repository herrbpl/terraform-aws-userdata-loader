variable "aws_region" {
  type = "string"
  default = "eu-central-1"
}
variable "name" {
    description = "Environment name, used as bucket prefix"
    default     = "bootscripts"
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

variable "scripts" {
  type = map(object({
    name            = string
    template        = string
    vars            = map(string)
  }))

  default = { 
    a = {
        name = "Test",
        template = "../templates/user_data.sh",
        vars = {
            a = "1",
            b = "2",
        }    
    }
  }
}