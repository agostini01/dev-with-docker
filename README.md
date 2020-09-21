# DEV with Docker

This project has scripts to start development containers and mount the current
working directory for edits as the user and **not** as root.
This enables edits inside the container to not have permission issues outside
of the container.

`build-docker.sh` will create a brand new docker image and tag with your user
ID.

`start-docker.sh` will start the container and volume mount the work directory.

The user `developer` is added to the sudo group. Check the `Dockerfile` to
verify the default password.

## Usage

Call `build-docker.sh` once to build an image for your user, then call
`start-docker.sh` from the folder of your project. This will volume mount
that folder as `/working_dir/` and changes to it will be persistent.

## Software stack

The `dockerfile` installs a range of development tools.  Currently, these tools
support `mlir-hlo`, `llvm`, `tensorflow` project compilation needs.
