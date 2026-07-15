#!/usr/bin/env bash
# Usage: xcodebuild ... 2>&1 | scripts/ci-log-filter.sh
# Drops known-benign xcodebuild noise so real warnings stand out in CI logs:
# upstream mlx-swift Metal kernels warn C++17-extensions on CI's Metal
# compiler, and SPM schemes always emit destination/simulator chatter.
# awk (not grep -v) so the filter never contributes a nonzero exit under
# `set -o pipefail` — only xcodebuild's own status decides the step.
exec awk '
/Wc\+\+17-extensions/ {next}
/^In file included from/ {next}
/warnings? generated\.$/ {next}
/if constexpr/ {next}
/^ *\^ *$/ {next}
/IDERunDestination/ {next}
/Using the first of multiple matching destinations/ {next}
/^[[:space:]]*\{ platform:/ {next}
/Found unhandled resource at .*checkouts/ {next}
/CoreSimulator is out of date|iOSSimulator:|DVTErrorPresenter|Domain: DVTCoreSimulatorAdditions/ {next}
{print}
'
