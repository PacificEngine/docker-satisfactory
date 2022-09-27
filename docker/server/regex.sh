#!/bin/bash
PERL_SCRIPT_LIBRARY="/server/perl"

regex() {
  perl -E "use lib '${PERL_SCRIPT_LIBRARY}'; use REGEX; my \$exp = REGEX->Arguments('--stdout', @ARGV); \$exp->Process();" -- "${@}"
}