#!/bin/bash

# create the data dir, if it doesn't exist
if ! test -d data; then
	mkdir data
fi

# if the data dir doesn't have an objectives.yaml, copy the default one over
if ! test -f data/objectives.yaml; then
	cp default_data/objectives.yaml data/objectives.yaml
fi

exec carton exec starman --port ${PORT:-1701} --preload-app /LockoutBoard/bin/app.psgi
