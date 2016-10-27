# go-dockerdev

* Git username will be set to "Christoph Zauner" in Dockerfile.
  Change if required.
  E.g. `git config --global user.name "Christoph Zauner"`.
* Git email will be set to "christoph.zauner@NLLK.net" in Dockerfile.
  Change if required.
  E.g. `git config --global user.email "christoph.zauner@NLLK.net"`.
* Linux user will be named `gopher`. Password will be randomly generated
  through Dockerfile when building the container and each time a container
  is run via the `run.sh` script. The `run.sh` script will print the
  password to `stdout`.

The following Go projects are checked out (see Dockerfile):

* github.com/zaunerc/cntrbrowserd
  * Using `go get`.
* github.com/zaunerc/cntrinfod
  * Using `go get`.
