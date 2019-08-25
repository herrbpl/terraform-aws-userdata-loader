provider "aws" {
  region = "${var.aws_region}"
}

locals {  
  cache_path = "${var.cache_path != "" ? var.cache_path : "${path.root}/cache" }"
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
      for ex in local.scripts: ex.name            
  ]
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

resource "aws_s3_bucket_object" "script_bootstrap" {
  count = local.scripts_count
  bucket = "${local.bucket_id}"
  key    = "${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip"
  etag   = "${data.archive_file.script_bootstrap[count.index].output_md5}"  
  source = "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip"    
}


data "template_file" "loader_script" {
  count = local.scripts_count
  template = "${file("${path.module}/templates/user_data_loader.sh")}"
  vars = {    
    bucket_account = "${data.aws_caller_identity.current.account_id}"
    bucket_accesskey = "${aws_iam_access_key.boot_user.id}"
    bucket_secret = "${aws_iam_access_key.boot_user.secret}"
    bucket_name = "${local.bucket_id}"
    bucket_key = "${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip"
    filename = lookup(local.scripts[ local.scripts_index[count.index] ], "filename", "default")    
    cleanup_cloudinit = var.cleanup_cloudinit
  }
}


resource "null_resource" "clean_zips" {    
    triggers = {
        build_number = "${timestamp()}"
    }
    provisioner "local-exec" {
        command = <<EOF
rm -f "${local.cache_path}"/*.zip
EOF
        interpreter = var.local_exec_interpreter
    }
    depends_on = ["aws_s3_bucket_object.script_bootstrap"]
}

resource "null_resource" "cleanup_destroy" {
 
  provisioner "local-exec" {
    when    = "destroy"
    command = <<EOF
rm -f "${local.cache_path}"/*
EOF
    interpreter = var.local_exec_interpreter
  }
}