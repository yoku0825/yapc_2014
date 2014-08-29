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

my $all_tables    = init_all_tables("./data");
my $country_table = $all_tables->{country};
my $language_table= $all_tables->{countrylanguage};
my $country_index = init_index(["continent"], $country_table);
my $language_index= init_index(["countrycode", "percentage"], $language_table);

my $sort_buffer;
my $count= my $evaluted= my $sorted= 0;

=pod
mysql56> EXPLAIN SELECT Name, Language, Population, Percentage 
    -> FROM Country INNER JOIN CountryLanguage ON Country.Code= CountryLanguage.CountryCode 
    -> WHERE Country.continent = 'Asia' 
    -> ORDER BY Percentage LIMIT 5;
+----+-------------+-----------------+------+------------------------------+------------------------------+---------+--------------------+------+--------------------------------------------------------+
| id | select_type | table           | type | possible_keys                | key                          | key_len | ref                | rows | Extra                                                  |
+----+-------------+-----------------+------+------------------------------+------------------------------+---------+--------------------+------+--------------------------------------------------------+
|  1 | SIMPLE      | Country         | ref  | index_continent              | index_continent              | 33      | const              |   51 | Using index condition; Using temporary; Using filesort |
|  1 | SIMPLE      | CountryLanguage | ref  | index_countrycode_percentage | index_countrycode_percentage | 3       | world.Country.Code |    2 | NULL                                                   |
+----+-------------+-----------------+------+------------------------------+------------------------------+---------+--------------------+------+--------------------------------------------------------+
2 rows in set (0.00 sec)
=cut

$evaluted++;
my $country_index_num   = $country_index->{map}->{Asia};
my $country_rownum_array= $country_index->{index}->[$country_index_num];

foreach my $country_rownum (@$country_rownum_array)
{
  my $country_row= $country_table->[$country_rownum];

  $evaluted++;
  my $language_index_num  = $language_index->{map}->{$country_row->{code}}->{self};
  my $language_index_range= $language_index->{index}->[$language_index_num];

  foreach my $language_rownum_array (@$language_index_range)
  {
    foreach my $language_rownum (@$language_rownum_array)
    {
      my $language_row= $language_table->[$language_rownum];

      $sorted++;
      push(@{$sort_buffer->{$language_row->{percentage}}},
           [$country_rownum, $language_rownum]);
    }
  }
}

my $sorted_buffer= filesort_single_column($sort_buffer);

foreach my $array (@$sorted_buffer)
{
  my ($country_rownum, $language_rownum)= @$array;

  my $country_row = $country_table->[$country_rownum];
  my $language_row= $language_table->[$language_rownum];

  printf("%s\t%s\t%d\t%f\n",
         $country_row->{name},
         $language_row->{language},
         $country_row->{population},
         $language_row->{percentage});
  if (++$count >= 5)
    {last;}
}

printf("\033[32mTotal rows evaluted are %d, sorted are %d.\n\033[0m", $evaluted, $sorted);

exit 0;


__END__
