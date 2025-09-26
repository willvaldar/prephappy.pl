#Copyright 2013 William Valdar
#This file is part of prephappy.

#prephappy is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#prephappy is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with prephappy.  If not, see <http://www.gnu.org/licenses/>.

package VarType;
use strict;
use English;
use StdDefs;
use Exporter;
use base qw(Exporter);
use vars qw( @EXPORT_OK );

@EXPORT_OK = qw(
        IsArrayRef
        IsHashRef
        IsNumber
        AsArray
        );

sub IsArrayRef($);
sub IsInt($);
sub IsHashRef($);
sub IsNumber($);

sub AsArray($)
{
    my $var = shift;
    
    return (IsArrayRef($var))
            ? $var
            : [$var];
}

sub IsArrayRef($)   { (ref($ARG[0]) =~ m/ARRAY/) ? true : false}
sub IsInt($)        { ($ARG[0] =~ m/^\d+$/) ? true : false}
sub IsHashRef($)    { (ref($ARG[0]) =~ m/HASH/) ?  true : false}
sub IsNumber($)     {(defined ParseNumber($ARG[0])) ? true : false}

sub ParseNumber($)
{
    use POSIX qw(strtod);
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $ERRNO = 0;
    my($num, $unparsed) = strtod($str);
    if (($str eq '') || ($unparsed != 0) || $ERRNO)
    {
        return undef;
    }
    else
    {
        return $num;
    } 
} 
