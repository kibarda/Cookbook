#!/bin/bash


# integrity check the summary file
# ################################

find recipes -name \*.md |sed -e "s;recipes/;;" | grep -vf SummaryBlacklist.txt | sort > /tmp/is_md.txt

cat recipes/SUMMARY.md |grep '(' | sed -e "s;.*(;;" -e "s;).*;;" |sort |grep -v '# Summary' > /tmp/is_summary.txt

if test "`comm -3 /tmp/is_md.txt /tmp/is_summary.txt|wc -l`" -ne 0; then
        echo "not all files are mapped to the summary!"
        echo " files found       |    files in summary"
        comm -3 /tmp/is_md.txt /tmp/is_summary.txt
        exit 1
fi



# integrity check the mds for absolute links to other recepies
# ############################################################
find recipes/ -name \*.md -exec grep 'https://docs.arangodb.com/cookbook' {} \; -print |sed "s;^recipes/\(.*\).md;\n   In file: recipes/\1.md\n\n;"> /tmp/mdlinks.txt

if test "`cat /tmp/mdlinks.txt | wc -l`" -gt 0; then
    echo "Found absolute link to other receipe: "
    echo
    cat /tmp/mdlinks.txt
    exit 2
fi

cd recipes

# build the GITBOOK
# #################

if test -f book.json; then
    echo "using pregerenarted book.json"
else
    cat > book.json <<EOF
{
  "gitbook": ">=2.0.0",
  "title": "ArangoDB Cookbook",
  "author": "ArangoDB GmbH",
  "description": "Cookbook for ArangoDB solutions - the multi-model NoSQL database",
  "plugins": ["toggle-chapters","piwik","addcssjs"],
  "pluginsConfig": {
      "piwik": {
          "URL": "www.arangodb.com/piwik/",
      "siteId": 12
      },
      "addcssjs": {
          "js": ["styles/header.js"],
          "css": ["styles/header.css"] 
      }
  },
  "pdf": {
    "fontSize": 12,
    "toc": true,
    "margin": {
      "right": 60,
      "left": 60,
      "top": 35,
      "bottom": 35
    }
  },
  "styles": {
    "website": "styles/website.css"
  }
}
EOF
fi

gitbook install
gitbook build . ./../cookbook


# integrity check the html for flat markdown links
# ################################################
cd ..
find cookbook/ -name \*.html -exec grep '\.md' {} \; -print |sed "s;^cookbook/\(.*\).html;\n   In file: recipes/\1.md\n\n;"> /tmp/mdlinks.txt

if test "`cat /tmp/mdlinks.txt | wc -l`" -gt 0; then
    echo "Found left over flat markdown links in the generated output: "
    echo
    cat /tmp/mdlinks.txt
    exit 3
fi


sed -i -e "s;VERSION_NUMBER;;" cookbook/styles/header.css cookbook/styles/header.js
