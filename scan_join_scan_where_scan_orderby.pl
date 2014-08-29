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
my $sort_buffer;
my $count= my $evaluted= my $sorted= 0;

=pod
mysql56> EXPLAIN SELECT Name, Language, Population, Percentage 
    -> FROM Country INNER JOIN CountryLanguage ON Country.Code= CountryLanguage.CountryCode 
    -> WHERE Country.continent = 'Asia' 
    -> ORDER BY Percentage LIMIT 5;
+----+-------------+-----------------+------+---------------+------+---------+------+------+----------------------------------------------------+
| id | select_type | table           | type | possible_keys | key  | key_len | ref  | rows | Extra                                              |
+----+-------------+-----------------+------+---------------+------+---------+------+------+----------------------------------------------------+
|  1 | SIMPLE      | CountryLanguage | ALL  | NULL          | NULL | NULL    | NULL |  984 | Using temporary; Using filesort                    |
|  1 | SIMPLE      | Country         | ALL  | NULL          | NULL | NULL    | NULL |  239 | Using where; Using join buffer (Block Nested Loop) |
+----+-------------+-----------------+------+---------------+------+---------+------+------+----------------------------------------------------+
2 rows in set (0.00 sec)
=cut

for (my $language_rownum= 0;
        $language_rownum < scalar(@$language_table);
        $language_rownum++)
{
  my $language_row= $language_table->[$language_rownum];

  for (my $country_rownum= 0;
          $country_rownum < scalar(@$country_table);
          $country_rownum++)
  {
    my $country_row= $country_table->[$country_rownum];

    $evaluted++;
    if ($language_row->{countrycode} eq $country_row->{code} &&
        $country_row->{continent} eq "Asia")
    {
      $sorted++;
      push(@{$sort_buffer->{$language_row->{percentage}}},
           [$language_rownum, $country_rownum]);
    }
  }
}

my $sorted_buffer= filesort_single_column($sort_buffer);

foreach my $array (@$sorted_buffer)
{
  my ($language_rownum, $country_rownum)= @$array;

  my $language_row= $language_table->[$language_rownum];
  my $country_row= $country_table->[$country_rownum];

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
