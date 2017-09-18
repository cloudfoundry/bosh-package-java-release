# java

To vendor java package into your release, run:

```
$ git clone https://github.com/bosh-packages/java-release
$ cd ~/workspace/your-release
$ bosh vendor-package openjdk-1.8 ~/workspace/java-release
```

Included packages:

- openjdk-1.8

To use `openjdk-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/openjdk-1.8/bosh/compile.env
java ...
```

To use `openjdk-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/openjdk-1.8/bosh/runtime.env
java ...
```

See [packages/openjdk-1.8-test](packages/openjdk-1.8-test) and [jobs/openjdk-1.8-test](jobs/openjdk-1.8-test) for example.

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## TODO

- add custom trust store building
