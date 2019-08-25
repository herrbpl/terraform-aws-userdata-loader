module "userdata" {
    source = "../."
    name = "testing-bucket"
    cleanup_cloudinit = "true"    
    #bucket = "tm-existing-bucket"
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
