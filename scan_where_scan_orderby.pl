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
use Data::Dumper;
use YAPC::Asia::Tokyo::2014::yoku0825;

my $all_tables   = init_all_tables("./data");
my $country_table= $all_tables->{country};
my $sort_buffer;
my $count= my $evaluted= my $sorted= 0;

=pod
mysql56> EXPLAIN SELECT Name, Continent, Population 
    -> FROM Country 
    -> WHERE Continent = 'Asia' 
    -> ORDER BY Population LIMIT 5;
+----+-------------+---------+------+---------------+------+---------+------+------+-----------------------------+
| id | select_type | table   | type | possible_keys | key  | key_len | ref  | rows | Extra                       |
+----+-------------+---------+------+---------------+------+---------+------+------+-----------------------------+
|  1 | SIMPLE      | Country | ALL  | NULL          | NULL | NULL    | NULL |  239 | Using where; Using filesort |
+----+-------------+---------+------+---------------+------+---------+------+------+-----------------------------+
1 row in set (0.00 sec)
=cut

for (my $rownum= 0; $rownum < scalar(@$country_table); $rownum++)
{
  my $row= $country_table->[$rownum];

  $evaluted++;
  if ($row->{continent} eq "Asia")
  {
    $sorted++;
    push(@{$sort_buffer->{$row->{population}}}, $rownum);
  }
}

my $sorted_buffer= filesort_single_column($sort_buffer);

foreach my $rownum (@$sorted_buffer)
{
  my $row= $country_table->[$rownum];

  printf("%s\t%s\t%d\n",
         $row->{name},
         $row->{continent},
         $row->{population});
  if (++$count >= 5)
    {last;}
}

printf("\033[32mTotal rows evaluted are %d, sorted are %d.\n\033[0m", $evaluted, $sorted);

exit 0;


__END__
