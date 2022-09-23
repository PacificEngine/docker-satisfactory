#!/usr/local/bin/perl
use strict;
use warnings;

my $scriptFileName="$0";
my $type='NONE';
my $expression='';
my $group='';
my $file='';
my $input='';
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
            "\t-r|--replace [Expression]\n" .
            "\t--regex [Regex]\n" .
            "\t[InputValue]\n";
    exit 1;
}

sub handleVariables {
    my $valueSet=0;
    my $value='';
    my $replace='';
    my $global='false';
    my $passedParameters='';
    my $additionalParameters='';
    my $length=$#ARGV;
    for (my $i=0; $i <= $length; $i++) {
        if ($ARGV[$i] eq '-c' || $ARGV[$i] eq '--count') { $i++; $value=$ARGV[$i]; $type='COUNT'; $valueSet++ }
        elsif ($ARGV[$i] eq '-e' || $ARGV[$i] eq '-ext' || $ARGV[$i] eq '--extract') { $i++; $value=$ARGV[$i]; $i++; $group=$ARGV[$i]; $type='EXTRACT'; $valueSet++ }
        elsif ($ARGV[$i] eq '-f' || $ARGV[$i] eq '--find') { $i++; $value=$ARGV[$i]; $type='FIND'; $valueSet++ }
        elsif ($ARGV[$i] eq '--file') { $i++; $file=$ARGV[$i]; }
        elsif ($ARGV[$i] eq '-g' || $ARGV[$i] eq '--global') { $global='true'; }
        elsif ($ARGV[$i] eq '--input') { $i++; $input=$ARGV[$i]; }
        elsif ($ARGV[$i] eq '-m' || $ARGV[$i] eq '--multiline') { $multiline='true'; }
        elsif ($ARGV[$i] eq '-r' || $ARGV[$i] eq '--replace') { $i++; $value=$ARGV[$i]; $i++; $replace=$ARGV[$i]; $type='REPLACE'; $valueSet++ }
        elsif ($ARGV[$i] eq '--regex') {  $i++; $value=$ARGV[$i]; $type='REGEX'; $valueSet++ }
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
            $expression="m/$value/gs";
        } elsif ($type eq 'EXTRACT') {
            $expression="m/$value/gs";
        } elsif ($type eq 'FIND') {
            $expression="m/$value/gs";
        } elsif ($type eq 'REPLACE') {
            $replace =~ "s/\\//\\\\//g";
            $expression="s/$value/$replace/gs";
        } else {
            die("Unknown Pattern Matcher")
        }
    }

}

sub processLine($) {
    my($line) = @_;
    if ($type eq 'COUNT') {
        my $number = () = $line =~ $expression;
        print "$line =~ $expression\n" //TODO
    } elsif ($type eq 'EXTRACT') {
        my @matches = $line =~ $expression;
        print "$line =~ $expression\n" //TODO
    } elsif ($type eq 'FIND') {
        $line =~ $expression;
        print "$line =~ $expression\n" //TODO
    } elsif ($type eq 'REPLACE') {
        $line =~ $expression;
        print "$line =~ $expression\n"; //TODO
    } elsif ($type eq 'REGEX') {
        $line =~ $expression;
        print "$line =~ $expression\n"; //TODO
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