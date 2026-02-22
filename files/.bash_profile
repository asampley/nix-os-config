# Set up the system, user profile, and related variables.
# /etc/profile will be sourced by bash automatically
# Set up the home environment profile.
if [ -f ~/.profile ]; then source ~/.profile; fi

# Honor per-interactive-shell startup file
if [ -f ~/.bashrc ]; then source ~/.bashrc; fi

# Allow per computer configuration when using guix
if [ -f ~/.bash_profile.local ]; then source ~/.bash_profile.local; fi
