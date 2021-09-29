#!/bin/bash

## check if your repo is dirty
if [[ $(git diff --stat) != '' ]]; then
  echo -e "\033[31;1;4mYou have uncommited change, please clean your repository before creating a release\033[0m"
  exit 1
fi

## check you are up to date
if ! git diff --quiet -- remotes/origin/HEAD; then
  echo -e "\033[31;1;4mYou are not up to date with origin please pull before continue\033[0m"
  exit 1 
fi
## Get last version
lastVersion=$(git tag --sort=committerdate --list 'v[0-9]*' | tail -n 1)

## New version builder
PS3='Which kind of change did you made: '
options=("Major" "Minor" "Patch" "Manual")
select opt in "${options[@]}"
do
    case $opt in
        "Major" | "1")
            major=$(( $(echo ${lastVersion:1} | cut -d. -f1) + 1 ))
            newVersion="v${major}.0.0"
            echo "You made a major update."
            echo -e "Version change $lastVersion -> $newVersion"
            break;
            ;;
        "Minor" | "2")
            major=$(echo ${lastVersion:1} | cut -d. -f1)
            minor=$(( $(echo ${lastVersion:1} | cut -d. -f2) + 1 ))
            newVersion="v${major}.${minor}.0"
            echo "You made a minor update."
            echo -e "Version change $lastVersion -> $newVersion"
            break;
            ;;
        "Patch" | "3")
            major=$(echo ${lastVersion:1} | cut -d. -f1)
            minor=$(echo ${lastVersion:1} | cut -d. -f2)
            patch=$(( $(echo ${lastVersion:1} | cut -d. -f3) + 1 ))
            newVersion="v${major}.${minor}.${patch}"
            echo "You made a patch update."
            echo -e "Version change $lastVersion -> $newVersion"
            break;
            ;;
        "Manual" | "4")
            read -p "Enter new version number (vX.X.X):" newVersion;
            rx='^v([0-9]+\.){2,2}(\*|[0-9]+)(\-.*){0,1}$'
            if [[ ! $newVersion =~ $rx ]]; then
                echo -e "\033[31;1;4mNew version do not match with pattern vX.X.X\033[0m"
                exit 1
            fi
            echo -e "Version change $lastVersion -> $newVersion"
            break;
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

## Release confirmation
read -p "Do the release ? (y/N):" confirm;
confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
if [[ $confirm != "y" ]] && [[ $confirm != "yes" ]]; then
    echo "Release canceled.";
    exit 1;
fi

## lets release
git fetch -f --tags
git tag -a $newVersion -m "$newVersion"
git push --tags

echo "Your release is in progress, you can follow progress here: https://github.com/ankorstore/kubernetes-deploy-pilot/actions"