use strict;
use warnings;
use Devel::InPackage qw(in_package);
use Test::TableDriven (
    trivial => { 1 => 'main' },
    foo     => { 1 => 'main', 2 => 'Foo' },
    bar     => { 1 => 'main', 2 => 'Foo', 4 => 'Bar' },
    nested  => { 1 => 'main', 3 => 'Foo', 5 => 'main' },
    class   => { 1 => 'main', 2 => 'Foo', 4 => 'main' },
    role    => { 1 => 'main', 2 => 'Foo', 4 => 'main' },
);

my %data = %{eval do { local $/; <DATA> }};
for my $func (keys %data){
    no strict 'refs';
    *{$func} = sub { my $line = shift; in_package( code => $data{$func}, line => $line ) };
}

runtests;

__DATA__
{ trivial => '1;',
  foo     => "package Foo;\n1;",
  bar     => "package Foo;\n1;\npackage Bar;\n1;",
  nested  => "{\n package Foo;\n 1;\n}\n2;\n",
  class   => "class Foo {\n <foo>\n}\n1;",
  role    => "role Foo with Baz {\n <foo>\n}\n1;",
};
