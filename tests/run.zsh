#!/usr/bin/env zsh
# Unit tests for the smartty history parser and suggestion engine.
# Run with: zsh tests/run.zsh

SMARTTY_TEST_ROOT=${${(%):-%N}:A:h:h}

for smartty_test_file in state display history suggestions; do
    source "$SMARTTY_TEST_ROOT/lib/smartty/$smartty_test_file.zsh" || exit 1
done

typeset -i PASS=0 FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        (( PASS++ ))
        print -r -- "ok   $desc"
    else
        (( FAIL++ ))
        print -r -- "FAIL $desc"
        print -r -- "     expected: $expected"
        print -r -- "     actual:   $actual"
    fi
}

fixture=$(mktemp)
trap 'rm -f "$fixture"' EXIT

cat > "$fixture" <<'EOF'
: 1700000001:0;git status
: 1700000002:0;git status
: 1700000003:0;git checkout main
plain command
: 1700000004:0;git status
: 1700000005:0;echo one \
two
: 1700000006:0;git checkout -b feature
: 1700000007:0;git checkout -b feature
: 1700000008:0;docker ps
: 1700000009:0;docker pull nginx
: 1700000010:0;ls -la
EOF

HISTFILE=$fixture

assert_eq "resolve honors HISTFILE" \
    "$fixture" "$(smartty_resolve_history_file)"

assert_eq "extract strips extended-history prefix" \
    "git status" "$(smartty_extract_history_command ': 1700000001:0;git status')"

assert_eq "extract keeps plain lines" \
    "plain command" "$(smartty_extract_history_command 'plain command')"

smartty_load_history -q

assert_eq "full-command frequency counted" \
    "3" "${SMARTTY_CMD_COUNT[git status]}"

assert_eq "plain (non-extended) lines indexed" \
    "1" "${SMARTTY_CMD_COUNT[plain command]}"

assert_eq "multiline commands not suggested" \
    "" "${SMARTTY_SEEN_COMMANDS[echo one$'\n'two]}"

assert_eq "multiline commands still counted in program stats" \
    "1" "${SMARTTY_COMMAND_FREQ[echo]}"

assert_eq "most frequent full command wins" \
    "git status" "$(smartty_get_suggestion 'git s')"

assert_eq "frequency ranks within same program" \
    "git checkout -b feature" "$(smartty_get_suggestion 'git checkout')"

assert_eq "recency breaks frequency ties" \
    "docker pull nginx" "$(smartty_get_suggestion 'docker p')"

assert_eq "exact prefix of itself matches" \
    "ls -la" "$(smartty_get_suggestion 'ls')"

assert_eq "no match returns nothing" \
    "" "$(smartty_get_suggestion 'zzz-nope')"

assert_eq "empty input returns nothing" \
    "" "$(smartty_get_suggestion '')"

assert_eq "glob characters in input are literal" \
    "" "$(smartty_get_suggestion 'git *')"

smartty_compute_matches 'git *' 5
assert_eq "glob input does not crash or match" "0" "${#SMARTTY_MATCHES[@]}"

smartty_get_suggestion 'git ['
assert_eq "unbalanced bracket input does not crash" "" "$SMARTTY_SUGGESTION"

smartty_compute_matches 'git' 3
assert_eq "top-N returns requested count" "3" "${#SMARTTY_MATCHES[@]}"
assert_eq "top-N is ranked" "git status" "${SMARTTY_MATCHES[1]}"

smartty_index_command 'git stash pop'
smartty_compute_matches 'git sta' 5
assert_eq "live-indexed command becomes suggestible" \
    "git stash pop" "${SMARTTY_MATCHES[2]}"

assert_eq "index trims surrounding whitespace" \
    "0" "$(smartty_index_command '   spaced out   '; print -r -- ${SMARTTY_CMD_COUNT[spaced out]:+0})"

print
print -r -- "passed: $PASS, failed: $FAIL"
(( FAIL == 0 ))
