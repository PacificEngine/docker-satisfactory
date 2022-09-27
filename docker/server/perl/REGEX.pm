#!/usr/local/bin/perl
package REGEX;
use strict;
use warnings;

my $scriptFileName="$0";

sub Arguments {
    my $class = shift;

    my $error='';
    my $type='NONE';
    my $expression='';
    my $group=0;
    my $stdin='false';
    my $file='';
    my $input='';
    my $iterator='false';
    my $stdout='false';
    my $output='';
    my $global='false';
    my $multiline='false';
    my $replace='';
    my $trim='false';
    my $passedParameters='';
    my $additionalParameters='';

    # Process Parameters
    my @parameters=();
    my $length=$#_;
    for (my $i=0; $i <= $length; $i++) {
        if (ref($_[$i]) eq 'ARRAY') {
            my @array = @$_[$i];
            for (my $j=0; $j <= $#array; $j++) {
                push(@parameters, $array[$j]);
            }
        } else {
            push(@parameters, $_[$i]);
        }
    }

    # Parse Parameters
    $length=$#parameters;
    for (my $i=0; $i <= $length; $i++) {
        if ($parameters[$i] eq '-c' || $parameters[$i] eq '--count') {
            if ($type ne 'NONE' && $type ne 'FIND') {
                $error.="\nCannot use COUNT with $type.";
            } else {
                $type='COUNT';
            }
        } elsif ($parameters[$i] eq '-e' || $parameters[$i] eq '-ext' || $parameters[$i] eq '--extract') {
            if ($type ne 'NONE' && $type ne 'FIND') {
                $error.="\nCannot use EXTRACT with $type.";
            } else {
                $replace=$parameters[++$i];
                $type='EXTRACT';
            }
        } elsif ($parameters[$i] eq '-f' || $parameters[$i] eq '--find') {
            if ($type ne 'NONE' && $type ne 'COUNT' && $type ne 'EXTRACT' && $type ne 'GROUP' && $type ne 'REPLACE') {
                $error.="\nCannot use FIND with $type.";
            } else {
                $expression=$parameters[++$i];
                $type='FIND';
            }
        } elsif ($parameters[$i] eq '--file') {
            $file=$parameters[++$i];
        } elsif ($parameters[$i] eq '-g' || $parameters[$i] eq '--global') {
            $global='true';
        } elsif ($parameters[$i] eq '--group') {
            if ($type ne 'NONE' && $type ne 'FIND') {
                $error.="\nCannot use GROUP with $type.";
            } else {
                $group=$parameters[++$i];
                $type='GROUP';
            }
        } elsif ($parameters[$i] eq '--iterator') {
            $iterator='true';
        } elsif ($parameters[$i] eq '--input') {
            $input=$parameters[++$i];
        } elsif ($parameters[$i] eq '-m' || $parameters[$i] eq '--multiline') {
            $multiline='true';
        } elsif ($parameters[$i] eq '--output') {
            $output=$parameters[++$i];
        } elsif ($parameters[$i] eq '-r' || $parameters[$i] eq '--replace') {
            if ($type ne 'NONE' && $type ne 'FIND') {
                $error.="\nCannot use REPLACE with $type.";
            } else {
                $replace=$parameters[++$i];
                $type='REPLACE';
            }
        } elsif ($parameters[$i] eq '--stdin') {
            $stdin='true';
        } elsif ($parameters[$i] eq '--stdout') {
            $stdout='true';
        } elsif ($parameters[$i] eq '-t' || $parameters[$i] eq '--trim') {
            $trim='true';
        } elsif ($parameters[$i] eq '--') {
            for ($i++;$i <= $length; $i++) {
                $passedParameters.=' ' . $parameters[$i];
            }
        } else {
            $additionalParameters.=' ' . $parameters[$i];
        }
    }

    # Normalize Parameters
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

    $expression =~ s/\//\\\//g ;
    $replace =~ s/\\/\\\\/g ;
    $replace =~ s/"/\"/g ;
    $replace = '"' . $replace . '"';

    # Validate Parameters
    if ($type eq 'NONE' && $trim eq 'false') {
        $error.="\nRequires one of Count, Expression, Extract, Find, Group, Replace, or Trim.";
    }
    if (length($passedParameters)) {
        $error.="\nPassed Parameters are not used.";
    }
    if ($stdin eq 'true' && length($file) && length($input)) {
        $error.="\nSTDIN & FILE & INPUT cannot all be used. Must choose one.";
    } elsif (length($file) && length($input)) {
        $error.="\nFILE & INPUT cannot both be used.";
    } elsif ($stdin eq 'true' && length($file)) {
        $error.="\nSTDIN & FILE cannot both be used.";
    } elsif ($stdin eq 'true' && length($input)) {
        $error.="\nSTDIN & INPUT cannot both be used.";
    }
    if ($stdout eq 'true' && length($output) && $iterator eq 'true') {
        $error.="\nSTDOUT & OUTPUT & ITERATOR cannot all be used. Must choose one.";
    } elsif (length($output) && $iterator eq 'true') {
        $error.="\nOUTPUT & ITERATOR cannot both be used.";
    } elsif ($stdout eq 'true' && length($output)) {
        $error.="\nSTDOUT & OUTPUT cannot both be used.";
    } elsif ($stdout eq 'true' && $iterator eq 'true') {
        $error.="\nSTDOUT & ITERATOR cannot both be used.";
    }

    if (length($error)) {
        $error=substr($error, 1);
        die("$error\n" .
            "Usage: perl $scriptFileName\n" .
                "\t-c|--count\n" .
                "\t-e|--ext|--extract [Expression]\n" .
                "\t-f|--find [Expression]\n" .
                "\t--file [InputFilePath]\n" .
                "\t-g|--global\n" .
                "\t--group [Group]\n" .
                "\t--iterator\n" .
                "\t--input [InputValue]\n" .
                "\t-m|--multiline\n" .
                "\t-r|--replace [Replacement]\n" .
                "\t--stdin\n" .
                "\t--stdout\n" .
                "\t-t|--trim\n" .
                "\t[InputValue]\n");
    }

    # Default Parameters
    if ($stdin eq 'false' && !length($input) && !length($file)) {
        $stdin='true'
    } elsif ($stdout eq 'false' && !length($output) && $iterator eq 'false') {
        $stdout='true'
    }

    my $self = bless {
        'type'=> $type,
        'global'=> $global,
        'multiline'=> $multiline,
        'stdin'=> $stdin,
        'input'=> $input,
        'file'=> $file,
        'stdout'=> $stdout,
        'iterator'=> $iterator,
        'output'=> $output,
        'expression'=> $expression,
        'replace'=> $replace,
        'group'=> $group,
        'trim'=> $trim
    }, $class;

    return $self;
}

my $getMatches = sub($) {
    my ($self,$line) = @_;
    my @matches = ();
    if ($self->{global} eq 'true') {
        if ($self->{multiline} eq 'true') {
            while($line =~ m/$self->{expression}/gs) {
                push(@matches, [ $-[$self->{group}], $+[$self->{group}] ]);
            }
        } else {
            while($line =~ m/$self->{expression}/g) {
                push(@matches, [ $-[$self->{group}], $+[$self->{group}] ]);
            }
        }
    } else {
        if ($self->{multiline} eq 'true') {
            if ($line =~ m/$self->{expression}/s) {
                push(@matches, [ $-[$self->{group}], $+[$self->{group}] ]);
            }
        } else {
            if ($line =~ m/$self->{expression}/) {
                push(@matches, [ $-[$self->{group}], $+[$self->{group}] ]);
            }
        }
    }
    return @matches;
};

my $doSubstitution = sub($) {
    my ($self,$line) = @_;
    if ($self->{global} eq 'true') {
        if ($self->{multiline} eq 'true') {
            $line =~ s/$self->{expression}/$self->{replace}/gsee ;
        } else {
            $line =~ s/$self->{expression}/$self->{replace}/gee ;
        }
    } else {
        if ($self->{multiline} eq 'true') {
            $line =~ s/$self->{expression}/$self->{replace}/see ;
        } else {
            $line =~ s/$self->{expression}/$self->{replace}/ee ;
        }
    }
    return $line;
};

my $processLine = sub($) {
    my ($self,$line) = @_;

    # Preform Regex
    my @results = ();
    if ($self->{type} eq 'COUNT' || $self->{type} eq 'EXTRACT' || $self->{type} eq 'FIND' || $self->{type} eq 'GROUP') {
        my @matches = $self->$getMatches($line);
        if ($self->{type} eq 'COUNT') {
            push(@results, scalar(@matches));
        } elsif ($self->{type} eq 'GROUP' || $self->{type} eq 'FIND') {
            foreach my $match (@matches) {
                push(@results, substr($line, @$match[0], @$match[1] - @$match[0]));
            }
        } elsif ($self->{type} eq 'EXTRACT') {
            foreach my $match (@matches) {
                push(@results, $self->$doSubstitution(substr($line, @$match[0], @$match[1] - @$match[0])));
            }
        } else {
            die("Unknown Pattern Matcher");
        }
    } elsif ($self->{type} eq 'REPLACE') {
        push(@results, $self->$doSubstitution($line));
    } elsif ($self->{trim} eq 'true') {
        push(@results, $line);
    } else {
        die("Unknown Pattern Matcher");
    }

    # Trim
    my @output = ();
    if ($self->{trim} eq 'true') {
        foreach my $result (@results) {
            $result =~ s/(^\s+|\s+$)//g ;
            push(@output, $result);
        }
    } else {
        @output = @results;
    }

    return @output;
};

my $processInput = sub {
    my $self = shift;
    my @output = ();
    my @lines = ();

    if (length($self->{file})) {
        open(INPUT, $self->{file}) or die('Could not open ' . $self->{file});
    } elsif (length($self->{input})) {
        @lines = split("\n", $self->{input});
    }

    return sub {
        my $multilineVal='';
        if (scalar @output > 0) {
            return pop(@output);
        } elsif ($self->{stdin} eq 'true') {
            while (my $line = <STDIN>) {
                if ($self->{multiline} eq 'true') {
                    $multilineVal.="$line";
                } else {
                    chomp($line);
                    @output = $self->$processLine($line);
                    if (scalar @output > 0) {
                        return pop(@output);
                    }
                }
            }
            if (length($multilineVal)) {
                @output = $self->$processLine($multilineVal);
                if (scalar @output > 0) {
                    return pop(@output);
                }
            }
            return undef;
        } elsif (length($self->{file})) {
            while (my $line = <INPUT>) {
                if ($self->{multiline} eq 'true') {
                    $multilineVal.="$line";
                } else {
                    chomp($line);
                    @output = $self->$processLine($line);
                    if (scalar @output > 0) {
                        return pop(@output);
                    }
                }
            }
            if (length($multilineVal)) {
                @output = $self->$processLine($multilineVal);
                if (scalar @output > 0) {
                    return pop(@output);
                }
            }
            close(INPUT);
            return undef;
        } elsif (length($self->{input})) {
            while (my $line = pop(@lines)) {
                if ($self->{multiline} eq 'true') {
                    $multilineVal.="$line\n";
                } else {
                    chomp($line);
                    @output = $self->$processLine($line);
                    if (scalar @output > 0) {
                        return pop(@output);
                    }
                }
            }
            if (length($multilineVal)) {
                @output = $self->$processLine($multilineVal);
                if (scalar @output > 0) {
                    return pop(@output);
                }
            }
            return undef;
        } else {
            die('Bad Input');
        }
    }
};

my $processOutput = sub {
    my ($self,$line) = @_;
    if (length($self->{output})) {
        print OUTPUT $line . "\n";
    } elsif ($self->{stdout} eq 'true') {
        print STDOUT $line . "\n";
    } else {
        die('Bad Output');
    }
};

sub Process {
    my $self = shift;
    my $next = $self->$processInput();
    if (length($self->{output})) {
        open(OUTPUT, $self->{output}) or die('Could not open ' . $self->{output});
    }
    if ($self->{iterator} eq 'true') {
        return $next;
    } else {
        while ( my $output = $next->() ) {
            $self->$processOutput($output);
        }
    }
    if (length($self->{output})) {
        close(OUTPUT);
    }
}

1;