#!/bin/bash

TWINCAT_PROJECT_ROOT=${TWINCAT_PROJECT_ROOT:-$TRAVIS_BUILD_DIR}

cd $TWINCAT_PROJECT_ROOT

pip install git+https://github.com/slaclab/pytmc.git@v2.4.0

EXIT_CODE=0

find . -name '*.tsproj' -print0 | 
    while IFS= read -r -d '' tsproj; do 
        echo "Pragma lint results"
        echo "-------------------"
        echo '```'
        pytmc pragmalint --verbose "$tsproj"
        if [ $? -ne 0 ]; then
            EXIT_CODE=1
        fi
        echo '```'
    done

find . -name '*.tmc' -print0 |
    while IFS= read -r -d '' tmc; do
        db_errors=$(( ( pytmc db --allow-errors "$tmc") 1>/dev/null) 2>&1)

        echo "$(basename $tmc)"
        echo "=================="
        echo ""

        if [ ! -z "$db_errors" ]; then
            echo "Errors"
            echo "------"
            echo '```'
            echo "$db_errors"
            echo '```'
            echo ""

            if [ $? -ne 0 ]; then
                EXIT_CODE=2
            fi
        fi

        echo "Records"
        echo "-------"
        echo '```'
        grep "^record" $db_filename | sed -e 's/^record(\(.*\),\(.*\)).*$/\2 (\1)/' | sort
        echo '```'
        echo ""

        echo "EPICS database"
        echo "--------------"
        echo '```'
        pytmc db --allow-errors "$tmc" 2> /dev/null
        echo '```'
    done

exit $EXIT_CODE
