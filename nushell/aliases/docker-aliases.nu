#
# Docker aliases and interactive commands
#

# Interactive docker compose file selector with fzf
export def fzd [] {
    let compose_file = (
        glob **/{docker-compose.yml,docker-compose.yaml,compose.yml,compose.yaml}
        | where ($it | path exists)
        | str join "\n"
        | fzf --height=40% --prompt="Select docker-compose file: " --preview="cat {}"
    )
    
    if ($compose_file | is-empty) {
        print "No file selected"
        return
    }
    
    print $"Starting docker compose with ($compose_file)..."
    docker compose -f $compose_file up -d
}