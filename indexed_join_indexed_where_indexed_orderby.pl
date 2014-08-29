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
my $country_index = init_index(["code", "continent"], $country_table);
my $language_index= init_index(["percentage"], $language_table);

my $sort_buffer;
my $count= my $evaluted= my $sorted= 0;

=pod
mysql56> EXPLAIN SELECT Name, Language, Population, Percentage
    -> FROM CountryLanguage STRAIGHT_JOIN Country ON Country.Code= CountryLanguage.CountryCode
    -> WHERE Country.continent = 'Asia'
    -> ORDER BY Percentage LIMIT 5;
+----+-------------+-----------------+-------+----------------------+----------------------+---------+-----------------------------------------+------+-----------------------+
| id | select_type | table           | type  | possible_keys        | key                  | key_len | ref                                     | rows | Extra                 |
+----+-------------+-----------------+-------+----------------------+----------------------+---------+-----------------------------------------+------+-----------------------+
|  1 | SIMPLE      | CountryLanguage | index | NULL                 | index_percentage     | 4       | NULL                                    |    5 | NULL                  |
|  1 | SIMPLE      | Country         | ref   | index_code_continent | index_code_continent | 36      | world.CountryLanguage.CountryCode,const |    1 | Using index condition |
+----+-------------+-----------------+-------+----------------------+----------------------+---------+-----------------------------------------+------+-----------------------+
2 rows in set (0.00 sec)
=cut

my $language_cardinality= scalar(keys(%{$language_index->{map}}));
LOOP: for (my $language_index_num= 0;
              $language_index_num < $language_cardinality;
              $language_index_num++)
{
  $evaluted++;
  my $language_rownum_array= $language_index->{index}->[$language_index_num];
  foreach my $language_rownum (@$language_rownum_array)
  {
    my $language_row= $language_table->[$language_rownum];
    my $country_index_num_first= $country_index->{map}->{$language_row->{countrycode}}->{self};
    my $country_index_num_second= $country_index->{map}->{$language_row->{countrycode}}->{Asia};

    if (!(defined($country_index_num_second)))
      {next;}

    $evaluted++;
    my $country_rownum_array=
      $country_index->{index}->[$country_index_num_first]->[$country_index_num_second];

    foreach my $country_rownum (@$country_rownum_array)
    {
      my $country_row= $country_table->[$country_rownum];

      printf("%s\t%s\t%d\t%f\n",
             $country_row->{name},
             $language_row->{language},
             $country_row->{population},
             $language_row->{percentage});
      if (++$count >= 5)
        {last LOOP;}
    }
  }
}

printf("\033[32mTotal rows evaluted are %d, sorted are %d.\n\033[0m", $evaluted, $sorted);

exit 0;


__END__
