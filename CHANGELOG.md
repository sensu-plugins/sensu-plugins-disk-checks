Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

#### Pending

remove check-disk.rb in favor of check-disk-usage.rb

#### 0.0.1.alpha.6

* add Chef provisioning to Vagrantfile
* add gem metadata
* update contributing
* fix rubocop issues to ensure passing status

#### 0.0.1.alpha.5

* remove check-fs-writable and place it in sensu-plugins-filesystem-checks

#### 0.0.1.alpha.4

* refactored check-disk to use sys-filesystem gem instead of df, it is not 100% backwards compatible dur to the new use of objects vs, plain text
* depreciated check-disk in favor of check-disk-usage, it will be removed in the first stable release
* add pry as a development dependency
* updated README with more detailed installation instructions

#### 0.0.1.alpha.3

* add check-smart-status
* add check-smart
* add pry gem as a development dependency

#### 0.0.1.alpha.2

* bump Vagrant box to Cent 6.6
* update LICENSE and gemspec authors
* update README
* add required Ruby version *>= 1.9.3*
* add test/spec_help.rb

#### 0.0.1.alpha.1

* baseline release identical to **sensu-community-plugins** repo
* basic yard coverage
* pinned dependencies
* built against 1.9.3, 2.0, 2.1
* cryptographically signed
