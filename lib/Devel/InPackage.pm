package Devel::InPackage;
use strict;
use warnings;
use 5.010;

use Carp qw(confess);

use File::Slurp qw(read_file);

use Sub::Exporter -setup => {
    exports => ['in_package', 'scan'],
};

my $MODULE = qr/(?<package>[A-Za-z0-9:]+)/;

sub in_package {
    my %args = @_;
    # XXX: hope you don't want to know what package foo is in here:
    # package main;
    # { package Bar; <foo> }
    my $point = delete $args{line} || confess 'need line';

    my $result = 'main';
    my $line_number = 0;
    my $cb = sub {
        my ($line, $package, %info) = @_;
        $line_number++;
        if( $line_number >= $point ){
            $result = $package;
            return 0;
        }
        return 1;
    };

    scan( %args, callback => $cb);

    return $result;
}

sub scan {
    my %args = @_;

    my $program = $args{code} //
      ($args{file} && read_file($args{file})) //
        confess 'Need "file" or "code"';

    my $callback = $args{callback} // confess 'Need "callback"';

    # this is very crude, and makes incorrect assumptions about Perl
    # syntax
    my @state = ('main');
    my $line_no = 0;
    while( $program =~ /^(?<line>.+)$/mg ){
        my $line = $+{line};
        my $saved_line = $line;

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

        my $res = $callback->( $line, $state[-1], line_number => $line_no++ );
        return if !$res; # end early
    }

    return;
}

1;
