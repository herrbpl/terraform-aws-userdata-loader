provider "aws" {
  region = "${var.aws_region}"
}

locals {  
  cache_path = "${var.cache_path != "" ? var.cache_path : "${path.module}/cache" }"
  scripts_count = length(var.scripts)
  scripts = {
    for ex in var.scripts: 
      ex.name => merge({   
      name = "",
      template = "",
      vars = {}       
  }, ex)
    if ex.name != ""
  }
}

resource "random_string" "script_password" {
  length = 16
  special = true
  override_special = "!@-"
}

#data "template_file" "user_script_template" {
#  count = local.scripts_count
#  template = file(lookup(local.scripts[count.index], "template", "")
#  vars = {}
#}