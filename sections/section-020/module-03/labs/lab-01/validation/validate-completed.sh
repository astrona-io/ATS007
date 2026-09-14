#!/usr/bin/env bash
# Confirms a kyverno-test.yaml suite exists with the correct expectations
# and that `kyverno test` reports every expectation as met.

set -u

LAB_DIR="/root/lab"
TEST_FILE="${LAB_DIR}/kyverno-test.yaml"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "FAIL: missing required test suite at ${TEST_FILE}"
  exit 1
fi

# The suite must reference the seeded policy and both seeded resources.
for required in "require-team-label.yaml" "good-pod.yaml" "bad-pod.yaml"; do
  if ! grep -q "$required" "$TEST_FILE"; then
    echo "FAIL: ${TEST_FILE} does not reference '${required}'"
    exit 1
  fi
done

# Both outcomes must be asserted: a suite declaring only passes would not be
# testing that the rule actually rejects anything. (Which resource maps to
# which outcome is proven functionally by the `kyverno test` run below - an
# inverted pair makes the suite itself fail.)
if ! grep -qE '^[[:space:]]*result:[[:space:]]*pass[[:space:]]*$' "$TEST_FILE"; then
  echo "FAIL: ${TEST_FILE} does not assert any expected 'result: pass' outcome"
  exit 1
fi

if ! grep -qE '^[[:space:]]*result:[[:space:]]*fail[[:space:]]*$' "$TEST_FILE"; then
  echo "FAIL: ${TEST_FILE} does not assert any expected 'result: fail' outcome - the suite must assert that bad-pod is rejected"
  exit 1
fi

# Both resources must be named in the results, not just loaded.
for res in "good-pod" "bad-pod"; do
  if ! grep -qE "^[[:space:]]*resource:[[:space:]]*${res}[[:space:]]*$" "$TEST_FILE"; then
    echo "FAIL: ${TEST_FILE} has no results entry for resource '${res}'"
    exit 1
  fi
done

# The rule under test must be named explicitly.
if ! grep -qE '^[[:space:]]*rule:[[:space:]]*check-team-label[[:space:]]*$' "$TEST_FILE"; then
  echo "FAIL: ${TEST_FILE} does not assert against the 'check-team-label' rule"
  exit 1
fi

# Finally, the suite must actually pass when executed.
if ! test_output=$(cd "$LAB_DIR" && kyverno test . 2>&1); then
  echo "FAIL: 'kyverno test .' did not succeed in ${LAB_DIR}"
  echo "$test_output" | tail -5
  exit 1
fi

if echo "$test_output" | grep -qiE '[1-9][0-9]* tests? failed'; then
  echo "FAIL: 'kyverno test .' reported failing tests"
  echo "$test_output" | tail -5
  exit 1
fi

echo "PASS: kyverno-test.yaml asserts both outcomes correctly and the suite passes."
exit 0
