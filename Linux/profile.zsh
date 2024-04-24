readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

if [[ -f "${PC_CONFIG_PATH}/Linux/env.zsh" ]]; then
	source "${PC_CONFIG_PATH}/Linux/env.zsh"
fi

function setup_path() {
	local user_paths=(
		"${HOME}/.local/bin"
		"${HOME}/.local/share/nvim/mason/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	export PATH
}

function setup_environment() {
	setup_path

	if GPG_TTY="$(tty)"; then
		export GPG_TTY
	fi

	if command -v nvim >/dev/null; then
		export EDITOR='nvim'
		export MANPAGER='nvim +Man!'
	fi

	if [[ -s "${HOME}/.autojump/etc/profile.d/autojump.sh" ]]; then
		source "${HOME}/.autojump/etc/profile.d/autojump.sh"
	fi
}

function install_softwares() {
	if [[ ! -d "${HOME}/.autojump" ]]; then
		pushd /tmp >/dev/null
		rm -rf autojump
		git clone https://github.com/wting/autojump
		cd autojump
		python3 install.py
		popd >/dev/null
	fi
}

function setup_config() {
	if [[ ! -d "${HOME}/.config/nvim-config" ]]; then
		git clone https://github.com/adonis0147/nvim-config "${HOME}/.config/nvim-config"
		pushd "${HOME}/.config/nvim-config" >/dev/null
		bash "${HOME}/.config/nvim-config/install.sh"
		popd >/dev/null
	fi

	if [[ ! -f "${HOME}/.fzf.zsh" ]]; then
		cat >"${HOME}/.fzf.zsh" <<EOF
PREFIX='/usr/share/doc/fzf/examples'

# Auto-completion
# ---------------
source "\${PREFIX}/completion.zsh"

# Key bindings
# ------------
source "\${PREFIX}/key-bindings.zsh"
bindkey "^R" history-search-multi-word
EOF
	fi
}

setup_environment
install_softwares
setup_config
