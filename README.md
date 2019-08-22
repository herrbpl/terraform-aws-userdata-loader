# Summary

This is helper module to overcome cases where aws_launch_configuration size exceeds 16kb.
As workaround, S3 bucket is used to store actual init scripts and script loader is passed into aws_launch_configuration

Currently, there is no option to use preprovided bucket name.

# Prerequisites

* shells-style interpreter - for example bash in linux or git-bash in windows
* openssl in PATH for interpreter

# Examples

