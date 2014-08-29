#!/usr/bin/perl -Ilib

########################################################################
## Copyright (C) 2014  yoku0825
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; either version 2
## of the License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#########################################################################

use strict;
use warnings;
use Test::Base;
use YAPC::Asia::Tokyo::2014::yoku0825;
use Data::Dumper;

plan tests => 2 * blocks;

my $all_tables= init_all_tables("./data");
my $country_table= $all_tables->{country};
my $index_of_continent_name= init_index(["continent", "name"], $country_table);


filters
{
  str1 => qw/chomp/,
  str2 => qw/chomp/
};


run
{
  my $block= shift;

  ### Can I access rownum using $index->[$index->{map}->{hoge}]->[$index->{map}->{hoge}->{fuga}]->[0] ?
  my $mapped_num1= $index_of_continent_name->{map}->{$block->str1}->{self};
  my $mapped_num2= $index_of_continent_name->{map}->{$block->str1}->{$block->str2};
  my $rownums    = $index_of_continent_name->{index}->[$mapped_num1]->[$mapped_num2];
  my $rownums_where    = where($index_of_continent_name, [$block->str1, $block->str2]);
  my $row        = $country_table->[$rownums->[0]];
  my $row_where  = $country_table->[$rownums_where->[0]];
  is_deeply([$row->{continent}, $row->{name}], [$block->str1, $block->str2], $block->name . " basic");
  is_deeply([$row_where->{continent}, $row_where->{name}], [$block->str1, $block->str2], $block->name . " where");
};


exit 0;


__END__
=== North America => Aruba
--- str1
North America
--- str2
Aruba

=== Oceania => Cocos (Keeling) Islands
--- str1
Oceania
--- str2
Cocos (Keeling) Islands

=== Oceania => Cook Islands
--- str1
Oceania
--- str2
Cook Islands
