
#!/usr/bin/env bash

TAG=${TAG:-latest}

functions=./*
for f in $functions
do
    languages=$f/*
    for l in $languages
    do
        if [ -f "$l/package.json" ]
        then
            (cd $l && npm install)
        fi
        if [ -f "$l/Dockerfile" ]
        then
            name=$(basename $f)
            lang=$(basename $l)
            echo "building $name-$lang"
            (cd $l && docker build -t $DOCKER_USER/$name-$lang:$TAG . && docker push $DOCKER_USER/$name-$lang:$TAG)
        fi
    done
done
