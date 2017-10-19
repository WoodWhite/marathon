#!/bin/bash

set -x -e -o pipefail

# Two parameters are expected: CHANNEL and VARIANT where CHANNEL is the respective PR and
# VARIANT could be one of four custer variants: open, strict, permissive and disabled
if [ "$#" -ne 2 ]; then
    echo "Expected 2 parameters: <channel> and <variant> e.g. si.sh testing/pull/1739 open"
    exit 1
fi

CHANNEL="$1"
VARIANT="$2"

function create-junit-xml {
    local testsuite_name=$1
    local testcase_name=$2
    local error_message=$3

	cat > shakedown.xml <<-EOF
	<testsuites>
	  <testsuite name="$testsuite_name" errors="0" skipped="0" tests="1" failures="1">
	      <testcase classname="$testsuite_name" name="$testcase_name">
	        <failure message="test setup failed">$error_message</failure>
	      </testcase>
	  </testsuite>
	</testsuites>
	EOF
}

DCOS_URL=$( ./ci/launch_cluster.sh "$CHANNEL" "$VARIANT" | tail -1 )
CLUSTER_LAUNCH_CODE=$?
case $CLUSTER_LAUNCH_CODE in
  0)
      ./ci/system_integration "$DCOS_URL"
      ;;
  2)
      echo "Cluster launch failed."
      create-junit-xml "dcos-launch" "cluster.create" "Cluster launch failed."
      ./dcos-launch delete
      exit 0
      ;;
  3)
      echo "Cluster did not come up";
      create-junit-xml "dcos-launch" "cluster.create" "Cluster did not start in time."
      ./dcos-launch delete
      exit 0
      ;;
esac
