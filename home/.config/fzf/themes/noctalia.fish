set -l fzf_theme_opts "\
--color=bg+:#3c4b36
--color=bg:#0c1609
--color=spinner:#dae6d0
--color=hl:#ffb4ab
--color=fg:#dae6d0
--color=header:#ffb4ab
--color=info:#d0ffbe
--color=pointer:#dae6d0
--color=marker:#baccb0
--color=fg+:#dae6d0
--color=prompt:#d0ffbe
--color=hl+:#ffb4ab
--color=selected-bg:#3c4b36
--color=border:#3c4b36
--color=label:#dae6d0"

if set -q FZF_DEFAULT_OPTS[1]; and test -n "$FZF_DEFAULT_OPTS"
    set -Ux FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS
$fzf_theme_opts"
else
    set -Ux FZF_DEFAULT_OPTS "$fzf_theme_opts"
end
