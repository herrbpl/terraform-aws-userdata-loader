# Summary

This is helper module to overcome cases where aws_launch_configuration size exceeds 16kb.
As workaround, S3 bucket is used to store actual init scripts and script loader is passed into aws_launch_configuration

Currently, there is no option to use preprovided bucket name.

# Prerequisites

* shells-style interpreter - for example bash in linux or git-bash in windows
* openssl in PATH for interpreter

# Examples

## When not using module

`terraform.tfvars`:
```
local_exec_interpreter = ["C:/Program Files/Git/git-bash.exe", "-c"]
scripts = [
    {
        name = "bootstrap",
        filename = "bootstrap.sh"
        template = "a.sh",
        vars = {
            a = "Variable a!"
            b = "Variable b!"
        }    
    },
    {
        name = "masters",
        filename = "masters.sh"
        template = "a.sh",
        vars = {
            a = "Variable MASTER!"
            b = "Variable BLASTER!"
        }    
    },
    {
        name = "datas",
        filename = "datas.sh"
        template = "a.sh",
        vars = {
            a = "Variable DATAS!"
            b = "Variable DATAS!"
        }    
    }
  ]
```

`a.sh`: 

```
#/bin/bash
echo "This is a script"
echo "${a}"
echo "${b}"
```

## using module

```
module "userdata" {
    source = "../."
    name = "testing"
    local_exec_interpreter = ["C:/Program Files/Git/git-bash.exe", "-c"]
    scripts = [
    {
        name = "bootstrap",
        filename = "bootstrap.sh"
        template = "a.sh",
        vars = {
            a = "Variable a!"
            b = "Variable b!"
        }    
    },
    {
        name = "masters",
        filename = "masters.sh"
        template = "a.sh",
        vars = {
            a = "Variable MASTER!"
            b = "Variable BLASTER!"
        }    
    },
    {
        name = "datas",
        filename = "datas.sh"
        template = "a.sh",
        vars = {
            a = "Variable DATAS!"
            b = "Variable DATAS!"
        }    
    }
  ]
}

output "name" {
  value = module.userdata.scripts["datas"].content
}
```

# Todo

