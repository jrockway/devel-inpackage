package Devel::InPackage;
use strict;
use warnings;
use 5.010;

use Carp qw(confess);

use File::Slurp qw(read_file);

use Sub::Exporter -setup => {
    exports => ['in_package'],
};

my $MODULE = qr/(?<package>[A-Za-z0-9:]+)/;

sub in_package {
    my %args = @_;

    my $program = $args{code} //
      ($args{file} && read_file($args{file})) //
        confess 'Need "file" or "code"';

    # XXX: hope you don't want to know what package foo is in here:
    # package main;
    # { package Bar; <foo> }
    my $point = $args{line} || confess 'need line';


    # this is very crude, and makes incorrect assumptions about Perl
    # syntax
    my @state = ('main');
    my $line_no = 0;
    while( $program =~ /^(?<line>.+)$/mg ){
        my $line = $+{line};
        $line_no++;

        return $state[-1] if $line_no eq $point;

        # skip comments
        $line =~ s/#(.+)$//;

        while( $line =~ /(?<token>(?:
                                 { |
                                 } |
                                 \bpackage \s+ $MODULE \s* ; |
                                 \b(?:class|role) \s+ $MODULE (.+)? { ))
                        /xg ){
            given($+{token}){
                when('{'){
                    push @state, $state[-1];
                }
                when('}'){
                    confess "Unmatched closing } at $line_no" unless @state > 0;
                    pop @state;
                }
                when(/(package|class|role) ($MODULE)/){
                    push @state, $+{package};
                }
            }
        }
    }

    return $state[-1];
}

1;
