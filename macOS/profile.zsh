readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

if [[ -f "${PC_CONFIG_PATH}/macOS/env.zsh" ]]; then
	source "${PC_CONFIG_PATH}/macOS/env.zsh"
fi

function change_homebrew_mirror() {
	local content="export HOMEBREW_BOTTLE_DOMAIN='https://mirrors.aliyun.com/homebrew/homebrew-bottles'"
	if ! grep "${content}" "${PC_CONFIG_PATH}/macOS/env.zsh" &>/dev/null; then
		pushd "$(brew --repo)" >/dev/null
		git remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git
		popd

		brew update
		echo -e "${content}" >>"${PC_CONFIG_PATH}/macOS/env.zsh"

		source "${PC_CONFIG_PATH}/macOS/env.zsh"
	fi
}

function setup_path() {
	local user_paths=(
		"${HOMEBREW_PREFIX}/bin"
		"${HOMEBREW_PREFIX}/sbin"
		"${HOME}/.local/share/nvim/mason/bin"
		"${HOME}/.jenv/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	local cellars=(
		gnu-getopt
		llvm
	)
	for cellar in "${cellars[@]}"; do
		PATH="${HOMEBREW_PREFIX}/opt/${cellar}/bin:${PATH}"
	done

	export PATH
}

function setup_environment() {
	setup_path

	if command -v nvim >/dev/null; then
		export EDITOR='nvim'
		export MANPAGER='nvim +Man!'
	fi

	if [[ -s "${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh" ]]; then
		source "${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh"
	fi

	if command -v gtar >/dev/null; then
		alias tar='gtar'
	fi
}

function install_terminfo() {
	local ncurses="ncurses-6.5"
	pushd /tmp >/dev/null
	rm -rf "${ncurses}"
	curl -L "https://ftpmirror.gnu.org/ncurses/${ncurses}.tar.gz" -o - | tar -zxf -
	mkdir "${ncurses}/build"
	cd "${ncurses}/build"
	../configure --prefix="$(pwd)/ncurses" --disable-widec --with-default-terminfo-dir="${PC_CONFIG_PATH}/terminfo"
	make -j "$(nproc)"
	make install
	popd

	rm -rf "${HOME}/.terminfo"
	ln -snf "${PC_CONFIG_PATH}/terminfo" "${HOME}/.terminfo"
	rm -f "${HOME}/.terminfo/61/{alacritty,alacritty-direct}"
	ln -snf ${HOMEBREW_PREFIX}/Caskroom/alacritty/*/Alacritty.app/Contents/Resources/61/* "${HOME}/.terminfo/61"
}

function setup_config() {
	if [[ ! -L "${HOME}/.alacritty.toml" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/alacritty.toml" "${HOME}/.alacritty.toml"
	fi

	if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
		git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
	fi

	if [[ ! -L "${HOME}/.tmux.conf" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/tmux.conf" "${HOME}/.tmux.conf"
	fi

	if [[ ! -d "${HOME}/.config/nvim-config" ]]; then
		git clone https://github.com/adonis0147/nvim-config "${HOME}/.config/nvim-config"
		pushd "${HOME}/.config/nvim-config" >/dev/null
		bash "${HOME}/.config/nvim-config/install.sh"
		popd >/dev/null
	fi

	if [[ ! -d "${PC_CONFIG_PATH}/terminfo" ]]; then
		install_terminfo
	fi

	if [[ ! -f "${HOME}/.fzf.zsh" ]]; then
		cat >"${HOME}/.fzf.zsh" <<EOF
# Auto-completion
# ---------------
source "\${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"

# Key bindings
# ------------
source "\${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
bindkey "^R" history-search-multi-word
EOF
	fi
}

function install_cellars() {
	local cellars=(
		autojump
		bash
		ccache
		cmake
		coreutils
		fzf
		git
		gnu-getopt
		gnu-tar
		htop
		llvm
		neovim
		ninja
		npm
		python
		ripgrep
		tmux
		wget
	)

	for cellar in "${cellars[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/opt/${cellar}" ]]; then
			brew install "${cellar}"
		fi
	done
}

function install_casks() {
	local casks=(
		alacritty
		karabiner-elements
		keka
		stolendata-mpv
		scroll-reverser
		snipaste
	)

	for cask in "${casks[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/Caskroom/${cask}" ]]; then
			brew install --cask "${cask}"
		fi
	done
}

function install_rye() {
	if [[ ! -d "${HOME}/.rye" ]]; then
		curl -sSf https://rye-up.com/get | RYE_INSTALL_OPTION="--yes" bash

		local config_file="${HOME}/.rye/config.toml"
		if [[ -f "${config_file}" ]]; then
			local line='use-uv = true'
			if ! grep "${line}" "${config_file}" &>/dev/null; then
				sed '/\[behavior\]/ a \
'"${line}"'
				' "${config_file}" >"${config_file}.tmp"
				mv "${config_file}.tmp" "${config_file}"
			fi
		fi
	fi

	export PATH="${HOME}/.rye/shims:${PATH}"
}

function install_pip() {
	if [[ ! -d "${HOME}/.rye/tools/pip" ]]; then
		rye install pip
	fi

	if [[ ! -f "${HOME}/.pip/pip.conf" ]]; then
		mkdir -p "${HOME}/.pip"

		cat >"${HOME}/.pip/pip.conf" <<EOF
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF
	fi
}

setup_environment
change_homebrew_mirror
install_cellars
install_casks
install_rye
install_pip
setup_config
