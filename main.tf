provider "aws" {
  region = "${var.aws_region}"
}

locals {  
  cache_path = "${var.cache_path != "" ? var.cache_path : "${path.module}/cache" }"
  scripts_count = length(var.scripts)
  scripts = {
    for ex in var.scripts: 
      ex.name => merge({   
      name = "default",
      filename = "default",
      template = "default.tpl",
      vars = {}       
  }, ex)
    if ex.name != ""
  }
  scripts_index = [
      for ex in var.scripts: ex.name
  ]
}

resource "random_string" "script_password" {
  length = 16
  special = true
  override_special = "!@-"
}

data "template_file" "user_script_template" {
  count = local.scripts_count
  template = file(

        lookup(local.scripts[ local.scripts_index[count.index] ], "template", "")
        )
  vars = lookup(local.scripts[ local.scripts_index[count.index] ], "vars", {})
}

data "archive_file" "script_bootstrap" {
    count       = local.scripts_count
    type        = "zip"
    source_content = "${data.template_file.user_script_template[count.index].rendered}"
    source_content_filename = lookup(local.scripts[ local.scripts_index[count.index] ], "filename", "default")
    output_path = "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip"
}