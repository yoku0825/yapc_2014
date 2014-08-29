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

plan tests => 2 * blocks;

my $all_tables= init_all_tables("./data");
my $country_table= $all_tables->{country};
my $index_of_continent= init_index(["continent"], $country_table);


run
{
  my $block= shift;

  ### Can I access single rownum using $index->{index}->[$index->{map}->{hoge}]->[0] ?
  my $mapped_num= $index_of_continent->{map}->{$block->name};
  my $rownums   = $index_of_continent->{index}->[$mapped_num];
  my $rownums_where   = where($index_of_continent, [$block->name]);
  my $row       = $country_table->[$rownums->[0]];
  my $row_where = $country_table->[$rownums_where->[0]];
  is_deeply($row->{continent}, $block->name, $block->name . " basic");
  is_deeply($row_where->{continent}, $block->name, $block->name . " where");
};

exit 0;


__END__
=== Africa
=== Antarctica
=== Asia
=== Europe
=== North America
=== Oceania
=== South America
