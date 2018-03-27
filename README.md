# java

To vendor java package into your release, run:

```
$ git clone https://github.com/bosh-packages/java-release
$ cd ~/workspace/your-release
$ bosh vendor-package openjdk-9 ~/workspace/java-release
```

Included packages:

- openjdk-9
- openjdk-8

To use `openjdk-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/openjdk-9/bosh/compile.env
java ...
```

To use `openjdk-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/openjdk-9/bosh/runtime.env
java ...
```

See [packages/openjdk-9-test](packages/openjdk-9-test) and [jobs/openjdk-9-test](jobs/openjdk-9-test) for example.

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## TODO

- add custom trust store building to runtime.env
