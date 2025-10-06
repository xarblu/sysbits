#!/usr/bin/env perl

use v5.35;

my $out = "";
my $rule = "";

while (my $line = <>) {
    # entered a "rule" block
    if ($line =~ m/^rule\s+(\S+)$/) {
        $rule = $1;
    }

    # entered a "build" block (-> left "rule" block)
    if ($line =~ m/^build\s+.*$/) {
        $rule = "";
    }

    # prettify matching rules
    if ($rule) {
        if ($line =~ m/^(\s+description\s*=\s*)(\S+(?:\s+\S+)*)$/) {
            $line = "$1\e[32m$2\e[0m\n";
        }
    }

    $out .= $line;
}

print $out;
