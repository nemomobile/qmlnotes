#!/bin/bash

cat <<'EOT'
<?xml version='1.0' encoding='UTF-8'?>
<testdefinition version='0.1'>
  <suite name='qmlnotes-tests' domain='Applications' type='Functional'>
    <set name='functional_tests' description='Functional tests' feature='Notes'>
      <pre_steps>
        <step>qttasserver &amp;</step>
        <step expected_result='0'>/usr/share/qmlnotes-tests/notes.sh stash</step>
      </pre_steps>
EOT

for file in test_*.rb; do
    if [ "$file" = "qmlnotes_tester.rb" ]; then continue; fi

    desc=$(grep '^#DESCRIPTION:' $file | sed -e 's/^#DESCRIPTION: //')
    name=${file%.rb}
    name=${name#test_}
    cat <<EOT
      <case name='${name}' description='$desc'>
        <step expected_result='0'>ruby /usr/share/qmlnotes-tests/$file</step>
      </case>
EOT
done

cat <<'EOT'
      <post_steps>
        <step expected_result='0'>/usr/share/qmlnotes-tests/notes.sh unstash</step>
      </post_steps>
      <environments>
        <scratchbox>true</scratchbox>
        <hardware>true</hardware>
      </environments>
    </set>
  </suite>
</testdefinition>
EOT
