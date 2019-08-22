output "cache_path" {
  value = "${local.cache_path}"
}

output "scripts" {
    value = {        
        for ex in local.scripts_index:
        ex => {            
            index = index(keys(local.scripts), ex)
            content = data.template_file.loader_script[index(keys(local.scripts), ex)].rendered
        }        
    }
    sensitive  = true
}