#!/usr/local/bin/perl
use strict;
use warnings;

my $scriptFileName="$0";
my $type='NONE';
my $expression='';
my $group=0;
my $file='';
my $input='';
my $global='false';
my $multiline='false';

sub usage {
    my($error) = @_;
    print "$error\n" .
        "Usage: perl $scriptFileName\n" .
            "\t-c|--count [Expression]\n" .
            "\t-e|--ext|--extract [Expression] [Group]\n" .
            "\t-f|--find [Expression]\n" .
            "\t--file [InputFilePath]\n" .
            "\t-g|--global\n" .
            "\t--input [InputValue]\n" .
            "\t-m|--multiline\n" .
            "\t-r|--replace [Expression] [Replacement]\n" .
            "\t--regex [Regex]\n" .
            "\t-t|--trim\n" .
            "\t[InputValue]\n";
    exit 1;
}

sub handleVariables {
    my $valueSet=0;
    my $value='';
    my $replace='';
    my $passedParameters='';
    my $additionalParameters='';
    my $length=$#ARGV;
    for (my $i=0; $i <= $length; $i++) {
        if ($ARGV[$i] eq '-c' || $ARGV[$i] eq '--count') { $i++; $value=$ARGV[$i]; $type='COUNT'; $valueSet++; }
        elsif ($ARGV[$i] eq '-e' || $ARGV[$i] eq '-ext' || $ARGV[$i] eq '--extract') { $i++; $value=$ARGV[$i]; $i++; $group=$ARGV[$i]; $type='EXTRACT'; $valueSet++; }
        elsif ($ARGV[$i] eq '-f' || $ARGV[$i] eq '--find') { $i++; $value=$ARGV[$i]; $type='FIND'; $valueSet++; }
        elsif ($ARGV[$i] eq '--file') { $i++; $file=$ARGV[$i]; }
        elsif ($ARGV[$i] eq '-g' || $ARGV[$i] eq '--global') { $global='true'; }
        elsif ($ARGV[$i] eq '--input') { $i++; $input=$ARGV[$i]; }
        elsif ($ARGV[$i] eq '-m' || $ARGV[$i] eq '--multiline') { $multiline='true'; }
        elsif ($ARGV[$i] eq '-r' || $ARGV[$i] eq '--replace') { $i++; $value=$ARGV[$i]; $i++; $replace=$ARGV[$i]; $type='REPLACE'; $valueSet++; }
        elsif ($ARGV[$i] eq '-t' || $ARGV[$i] eq '--trim') { $value='(^\\s+|\\s+$)'; $replace=''; $type='REPLACE'; $global='true'; $valueSet++; }
        elsif ($ARGV[$i] eq '--') { $i++; for (;$i <= $length; $i++) { $passedParameters.=' ' . $ARGV[$i]; } }
        else { $additionalParameters.=' ' . $ARGV[$i]; }
    }
    if (length($passedParameters)) {
        $passedParameters=substr($passedParameters, 1);
    }
    if (length($additionalParameters)) {
        $additionalParameters=substr($additionalParameters, 1);
    }
    if (length($input) && length($additionalParameters)) {
        $input=$input . ' ' . $additionalParameters;
        $additionalParameters='';
    } elsif (length($additionalParameters)) {
        $input=$additionalParameters;
    }

    if ($type eq 'NONE') {
        usage('Requires on of Count, Expression, Extract, Find, nor Replace.');
    }
    if ($valueSet != 1) {
        usage('Requires no more than one of Count, Expression, Extract, Find, nor Replace.');
    }
    if (length($passedParameters)) {
        usage('Passed Parameters are not used.');
    }
    if (length($file) && length($input)) {
        usage('File & Input cannot both be used.');
    }

    my $flag='';
    if ($global eq 'true') {
        $flag.='g';
    }
    if ($multiline eq 'true') {
        $flag.='s';
    }
    if ($type eq 'REGEX') {
        $expression=$value;
    } else {
        $value =~ "s/\\//\\\\//g";
        if ($type eq 'COUNT') {
            $expression="$value";
        } elsif ($type eq 'EXTRACT') {
            $expression="$value";
        } elsif ($type eq 'FIND') {
            $expression="$value";
        } elsif ($type eq 'REPLACE') {
            $expression="$value";
            $replace =~ "s/\\//\\\\//g";
            $group=$replace;
        } else {
            die("Unknown Pattern Matcher")
        }
    }
}

sub getMatches($) {
    my($line) = @_;
    my @matches = ();
    if ($global eq 'true') {
        if ($multiline eq 'true') {
            while($line =~ m/$expression/gs) {
                push(@matches, [ $-[$group], $+[$group] ]);
            }
        } else {
            while($line =~ m/$expression/g) {
                push(@matches, [ $-[$group], $+[$group] ]);
            }
        }
    } else {
        if ($multiline eq 'true') {
            if ($line =~ m/$expression/s) {
                push(@matches, [ $-[$group], $+[$group] ]);
            }
        } else {
            if ($line =~ m/$expression/) {
                push(@matches, [ $-[$group], $+[$group] ]);
            }
        }
    }
    return @matches;
}

sub doSubstitution($) {
    my($line) = @_;
    my @matches = ();
    if ($global eq 'true') {
        if ($multiline eq 'true') {
            $line =~ s/$expression/$group/gs
        } else {
            $line =~ s/$expression/$group/g
        }
    } else {
        if ($multiline eq 'true') {
            $line =~ s/$expression/$group/s
        } else {
            $line =~ s/$expression/$group/
        }
    }
    return $line;
}

sub processLine($) {
    my($line) = @_;
    if ($type eq 'COUNT' || $type eq 'EXTRACT' || $type eq 'FIND') {
        my @matches = getMatches($line);
        if ($type eq 'COUNT') {
            print scalar @matches . "\n";
        } elsif ($type eq 'EXTRACT' || $type eq 'FIND') {
            foreach my $match (@matches) {
                print substr($line, @$match[0], @$match[1] - @$match[0]) . "\n";
            }
        }  else {
            die("Unknown Pattern Matcher");
        }
    } elsif ($type eq 'REPLACE') {
        print doSubstitution($line) . "\n";
    } else {
        die("Unknown Pattern Matcher");
    }
}

sub processInput {
    my $multilineVal='';
    if (!length($file) && !length($input)) {
        foreach my $line (<STDIN>) {
            if ($multiline eq 'true') {
                $multilineVal.="$line";
            } else {
                chomp($line); processLine($line);
            }
        }
    } elsif (length($file)) {
        open(INFO, $file) or die('Could not open ' . $file);
        foreach my $line (<INFO>)  {
            if ($multiline eq 'true') {
                $multilineVal.="$line";
            } else {
                chomp($line); processLine($line);
            }
        }
    } elsif (length($input)) {
        my @lines = split("\n", $input);
        foreach my $line (@lines) {
            if ($multiline eq 'true') {
                $multilineVal.="$line\n";
            } else {
                chomp($line); processLine($line);
            }
        }
    } else {
        die('Bad Input');
    }

    if (length($multilineVal)) {
        processLine($multilineVal);
    }
}

handleVariables();
processInput();