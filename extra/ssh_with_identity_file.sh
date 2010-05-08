#!/bin/bash
exec ssh -i `dirname $0`/ssh/private_key "$@"
