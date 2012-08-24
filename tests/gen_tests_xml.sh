#!/bin/bash

# There's a sleep after qttasserver to give it time to start before
# the first test case tries to talk to it. TODO: find better way.
cat <<'EOT'
<?xml version='1.0' encoding='UTF-8'?>
<testdefinition version='0.1'>
  <suite name='qmlnotes-tests' domain='Applications' type='Functional'>
    <set name='functional_tests' description='Functional tests' feature='Notes'>
      <pre_steps>
        <step>qttasserver &amp;</step>
        <step>sleep 60</step>
      </pre_steps>
EOT

for file in test_*.rb; do
    if [ "$file" = "qmlnotes_tester.rb" ]; then continue; fi

    desc=$(grep '^#DESCRIPTION:' $file | sed -e 's/^#DESCRIPTION: //')
    name=${file%.rb}
    name=${name#test_}
    # Note: the screen unlock is not done with mcetool because the dbus
    # policy on Nemo restricts it to root.
    cat <<EOT
      <case name='${name}' description='$desc'>
        <step expected_result='0'>/opt/tests/qmlnotes/notes.sh stash</step>
        <step expected_result='0'>dbus-send --print-reply --system --dest=com.nokia.mce /nokia/mce/request com.nokia.mce.request.req_tklock_mode_change string:unlocked</step>
        <step expected_result='0'>ruby /opt/tests/qmlnotes/$file</step>
        <step expected_result='0'>/opt/tests/qmlnotes/notes.sh unstash</step>
      </case>
EOT
done

cat <<'EOT'
      <environments>
        <scratchbox>true</scratchbox>
        <hardware>true</hardware>
      </environments>
    </set>
  </suite>
</testdefinition>
EOT
