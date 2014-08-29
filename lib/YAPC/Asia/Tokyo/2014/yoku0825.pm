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

use Fcntl;


sub init_all_tables
{
  my ($datadir)= @_;

  my $file_of_country           = $datadir . "/Country.tsv";
  my @fields_of_country         = qw/code name continent region surfacearia
                                     idepyear population lifeexpectancy gnp
                                     gnpold localname governmentform
                                     headofstate capital code2/;
  my $file_of_city              = $datadir . "/City.tsv";
  my @fields_of_city            = qw/id name countrycode district population/;
  my $file_of_countrylanguage   = $datadir . "/CountryLanguage.tsv";
  my @fields_of_countrylanguage = qw/countrycode language isofficial
                                     percentage/;

  my @country_table        = init_one_table(\@fields_of_country, $file_of_country);
  my @city_table           = init_one_table(\@fields_of_city, $file_of_city);
  my @countrylanguage_table= init_one_table(\@fields_of_countrylanguage,
                                            $file_of_countrylanguage);

  return {country         => \@country_table,
          city            => \@city_table,
          countrylanguage => \@countrylanguage_table};

}


sub init_one_table
{
  my ($fields, $file)= @_;
  my @ret;

  sysopen(my $fh, $file, O_RDONLY);
  while (my $row= <$fh>)
  {
    chomp($row);
    my $data= {};
    my @field_data= split(/\t/, $row);

    for (my $n= 0; $n < scalar(@$fields); $n++)
      {$data->{$fields->[$n]}= $field_data[$n];}

    push(@ret, $data);
  }

  return @ret;
}

sub init_index
{
  my ($column_name_array, $table_data)= @_;

  my $column_count= scalar(@$column_name_array);
  if ($column_count == 1)
    {return init_single_column_index($column_name_array->[0], $table_data);}
  elsif ($column_count == 2)
    {return init_double_column_index($column_name_array->[0], $column_name_array->[1], $table_data);}
  else
    {return 0;}
}


sub init_single_column_index
{
  my ($column_name, $table_data)= @_;
  my ($buff, $index, $map);

  ### create a map at first.
  for (my $rownum= 0; $rownum < scalar(@$table_data); $rownum++)
  {
    my $row= $table_data->[$rownum];
    $buff->{$row->{$column_name}}= 1;
  }

  my $n= 0;
  foreach my $column_value (column_sort($buff))
    {$map->{$column_value}= $n++;}

  ### create a index.
  for (my $rownum= 0; $rownum < scalar(@$table_data); $rownum++)
  {
    my $row= $table_data->[$rownum];
    my $mapped_num= $map->{$row->{$column_name}};
    push(@{$index->[$mapped_num]}, $rownum);
  }

  return {index => $index, map => $map, depth => 1};
}


sub init_index_dummy
{
  my ($index_orig)= @_;

  if ($index_orig->{depth} == 1)
    {return init_single_column_index_dummy($index_orig);}
  elsif ($index_orig->{depth} == 2)
    {return init_double_column_index_dummy($index_orig);}
  else
    {return 0;}
}


sub init_single_column_index_dummy
{
  my ($index_orig)= @_;
  my @ret;

  foreach my $indexed_value (column_sort($index_orig->{map}))
  {
    if ($indexed_value ne "self")
      {push(@ret, {$indexed_value => where($index_orig, [$indexed_value])});}
  }

  return \@ret;
}


sub init_double_column_index_dummy
{
  my ($index_orig)= @_;
  my @ret;

  foreach my $indexed_value (column_sort($index_orig->{map}))
  {
    my $dummy_index= {map   => $index_orig->{map}->{$indexed_value},
                      index => $index_orig->{index}->[$index_orig->{map}->{$indexed_value}->{self}],
                      depth => 1};
    push(@ret, {$indexed_value => init_single_column_index_dummy($dummy_index)});
  }

  return \@ret;
}
  

sub init_double_column_index
{
  my ($column_name_1, $column_name_2, $table_data)= @_;
  my ($buff, $index, $map);

  ### create a map at first.
  for (my $rownum= 0; $rownum < scalar(@$table_data); $rownum++)
  {
    my $row= $table_data->[$rownum];
    $buff->{$row->{$column_name_1}}->{$row->{$column_name_2}}= 1;
  }

  my $n= 0;
  foreach my $column_value_1 (column_sort($buff))
  {
    my $m= 0;
    foreach my $column_value_2 (column_sort($buff->{$column_value_1}))
      {$map->{$column_value_1}->{$column_value_2}= $m++;}
    $map->{$column_value_1}->{self}= $n++;
  }

  ### create a index.
  for (my $rownum= 0; $rownum < scalar(@$table_data); $rownum++)
  {
    my $row= $table_data->[$rownum];
    my $mapped_num1= $map->{$row->{$column_name_1}}->{self};
    my $mapped_num2= $map->{$row->{$column_name_1}}->{$row->{$column_name_2}};
    push(@{$index->[$mapped_num1]->[$mapped_num2]}, $rownum);
  }

  return {index => $index, map => $map, depth => 2};
} 


sub filesort_single_column
{
  my ($sort_buffer)= @_;
  my @ret;

  my @sorted_columns= column_sort($sort_buffer);
  foreach my $sorted_column_value (@sorted_columns)
    {foreach my $rownum_list ($sort_buffer->{$sorted_column_value})
       {foreach my $rownum (@$rownum_list)
          {push(@ret, $rownum);}}}
  return \@ret;
}
 

sub is_column_integer
{
  my (@keys)= @_;

  foreach my $value (@keys)
  {
    if ($value ne "self" && $value !~ /^[0-9\.]*$/)
      {return 0;}
  }
  return 1;
}


sub column_sort
{
  my ($sort_buffer)= @_;

  if (is_column_integer(keys(%$sort_buffer)))
    {return sort { $a <=> $b } keys(%$sort_buffer);}
  else
    {return sort { $a cmp $b } keys(%$sort_buffer);}

  return 0;
}


sub where
{
  my ($index, $key)= @_;

  if ($index->{depth} == 1 && scalar(@$key) == 1)
  {
    my $index_num= $index->{map}->{$key->[0]};
    return $index->{index}->[$index_num];
  }
  elsif ($index->{depth} == 2 && scalar(@$key) == 2)
  {
    my $index_num1= $index->{map}->{$key->[0]}->{self};
    my $index_num2= $index->{map}->{$key->[0]}->{$key->[1]};
    return $index->{index}->[$index_num1]->[$index_num2];
  }
  else
    {return 0;}
}


return 1;


__END__
