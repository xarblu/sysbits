#!/usr/bin/env perl

use v5.35;

# loosely based on cmake
# https://github.com/Kitware/CMake/blob/f2afbff2c48a0479cc129c8eb2cc40e9181f0c51/Source/cmLocalUnixMakefileGenerator3.cxx#L1232
sub prettify_description {
    my $rule = $_[0];
    my $key = $_[1];
    my $value = $_[2];

    # ANSI fmt e.g. 1;32 for bold green
    # clear by default
    my $fmt = "";

    # C/CXX depend
    if ($rule =~ m/^(?:(?:C|CXX)_(?:SCAN|DYNDEP).*)$/) {
        # bold magenta
        $fmt = "1;35";
    }

    # C/CXX objects
    if ($rule =~ m/^(?:(?:c|cxx)_COMPILER|(?:C|CXX)_COMPILER.*)$/) {
        # green
        $fmt = "32";
    }

    # C/CXX link
    if ($rule =~ m/^(?:(?:c|cxx)_LINKER|(?:C|CXX)_\S+_LINKER.*)$/) {
        # bold green
        $fmt = "1;32";
    }

    # "generate" commands
    if ($rule =~ m/^(?:CUSTOM_COMMAND(?:|_DEP)|REGENERATE_BUILD)$/) {
        # bold blue
        $fmt = "1;34";
    }

    # symlinks
    if ($rule =~ m/^(?:CMAKE_SYMLINK_LIBRARY)$/) {
        # cyan
        $fmt = "36";
    }

    if ($fmt) {
        return "${key}\e[${fmt}m${value}\e[0m\n";
    } else {
        return "${key}${value}\n";
    }
}

# HACK:
# Inject a space and backspace via printf before each command to keep the rule printed.
# Ninja will print this on the line *after* a rule - essentially creating an empty line.
# This empty the either get's replaced by the next rule or compiler output.
# Only minor issue is that this will always generate a stray line at the last rule.
sub keep_rule_hack {
    my $rule = $_[0];
    my $key = $_[1];
    my $value = $_[2];

    return $key . 'printf " \b" && ' . $value . "\n";
}

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

    # prettify rules
    if ($rule) {
        if ($line =~ m/^(\s+description\s*=\s*)(\S+(?:\s+\S+)*)$/) {
            $line = prettify_description($rule, $1, $2);
        }

        if ($line =~ m/^(\s+command\s*=\s*)(\S+(?:\s+\S+)*)$/) {
            $line = keep_rule_hack($rule, $1, $2);
        }
    }

    $out .= $line;
}

print $out;
