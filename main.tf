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

resource "null_resource" "script_bootstrap" {
    count = local.scripts_count
    triggers = {
      #script_content = join("\n",[fileexists("${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip.enc"), 
      #"${data.template_file.user_script_template[count.index].rendered}"])
      script_content = "${data.template_file.user_script_template[count.index].rendered}",
      zip_sha1 = "${data.archive_file.script_bootstrap[count.index].output_sha}",
      encfile  = fileexists("${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip.enc") 
    }

    provisioner "local-exec" {
      command = <<EOF
mkdir -p "${local.cache_path}"
echo "Zip file size: ${data.archive_file.script_bootstrap[count.index].output_size}, SHA1: ${data.archive_file.script_bootstrap[count.index].output_sha}"
rm -f "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip.enc"
openssl aes-256-cbc -salt -a -e -in "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip" -pbkdf2 -k ${random_string.script_password.result} -out "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip.enc" && \
rm -f "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip"
EOF
      interpreter = ["C:/Program Files/Git/git-bash.exe", "-c"]
    }
}


resource "aws_s3_bucket_object" "script_bootstrap" {
  count = local.scripts_count
  bucket = "${aws_s3_bucket.scripts.id}"
  key    = "${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip.enc"
  #content = "${data.template_file.master_userdata_script.rendered}"  
  source = "${local.cache_path}/${lookup(local.scripts[ local.scripts_index[count.index] ], "name", "default")}.zip.enc"  
}


resource "null_resource" "clean_zips" {    
    triggers = {
        build_number = "${timestamp()}"
    }
    provisioner "local-exec" {
        command = <<EOF
rm -f "${local.cache_path}"/*.zip >> $HOME/output.log;
EOF
        interpreter = ["C:/Program Files/Git/git-bash.exe", "-c"]
    }
    depends_on = ["null_resource.script_bootstrap"]
}