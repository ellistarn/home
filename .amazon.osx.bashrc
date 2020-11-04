# Aliases
alias ssh-dev="ssh $DEV_DESKTOP_HOST"
alias ssh-dev-multiplex="ssh $DEV_DESKTOP_HOST 'exit'"
alias ssh-dev-exit="ssh -O exit $DEV_DESKTOP_HOST"

function midway_login {
  mwinit && \
  ssh-add -D \
  ssh-add -K -t ${MIDWAY_TIMEOUT_SECONDS} && \
  open "https://midway.amazon.com"
}

# Authentication Setup
MIDWAY_TIMEOUT_SECONDS=43200 # 12 hours
if ! test `find ~/.ssh/id_rsa-cert.pub -mtime -${MIDWAY_TIMEOUT_SECONDS}s`
then
  midway_login
  ecr_login
fi
