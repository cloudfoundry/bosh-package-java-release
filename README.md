# java

To vendor java package into your release, run:

```
$ git clone https://github.com/bosh-packages/java-release
$ cd ~/workspace/your-release
$ bosh vendor-package openjdk-8 ~/workspace/java-release
```

Included packages:

- openjdk-17
- openjdk-11
- openjdk-8

To use `openjdk-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/openjdk-8/bosh/compile.env
javac ...
```

To use `openjdk-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/openjdk-8/bosh/runtime.env
java ...
```

See [jobs/openjdk-8-test](jobs/openjdk-8-test) for example.

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## TODO

- add custom trust store building to runtime.env
