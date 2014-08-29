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
use Test::More;
use YAPC::Asia::Tokyo::2014::yoku0825;

my $all_tables= init_all_tables("./data");
is_deeply(ref($all_tables), "HASH", "init_all_tables returns hashref");

my $country_table= $all_tables->{country};
is_deeply(ref($country_table), "ARRAY", "each table returns arrayref");

my $country_table_row= $country_table->[0];
is_deeply(ref($country_table_row), "HASH", "each row returns hashref");

my $retsum= 0;
foreach my $field (keys(%$country_table_row))
{
  if (ref($country_table_row->{$field}) ne "")
    {$retsum++;}
}
is_deeply($retsum, 0, "each field returns value");

done_testing();

exit 0;


__END__
