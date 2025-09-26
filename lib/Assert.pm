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

package Assert;
use base qw(Exporter);
use Exporter;
use English;
use Carp qw( confess cluck );
use StdDefs;
use strict;
use vars qw(@EXPORT);

@EXPORT = qw( Assert Prefer WrongNumArgsError Fatal Warn Moan);

sub Assert($$)
{
    my ($boolean, $message) = @ARG;

    unless ($boolean)
    {
        confess "Null Assertion: $message\n";
    }
}

 
sub Assert::CheckArgHash
# usage:
# CheckArgHash(\%hArg,
#             'optional' => [qw(times length each)],
#             );
# 
# CheckArgHash(\%hArg,
#             'required' => [qw(
#             -parent
#             )],
#             'optional' => [qw(
#             -initialfile
#             -dialogtitle
#             )],
{
    my($hSubArg, %hArg) = @ARG;

    if (exists $hArg{'required'})
    {
        for my $arg (@{$hArg{'required'}})
        {
            unless (exists $hSubArg->{$arg})
            {
                Fatal("Missing required argument \'$arg\' to method");
            }
        }
    }
    if (exists $hArg{'optional'})
    {
        my @allowedList = @{$hArg{'optional'}};
        push @allowedList, @{$hArg{'required'}}
                if exists $hArg{'required'};
        my %allowed = ();
        @allowed{@allowedList} = ();
        for my $arg (keys %$hSubArg)
        {
            unless (exists $allowed{$arg})
            {
                Fatal("Invalid argument \'$arg\' to method\n");
            }
        }
    }
    if (exists $hArg{'oneof'})
    {
        my $count = 0;
        for my $arg (keys %$hSubArg)
        {
            $count++ if exists $hSubArg->{$arg};
        }
        if (1 != $count)
        {
            Fatal("Method must take exactly one of "
                    .join(',', $hArg{'oneof'})
                    );
        }
    }
}

sub Prefer
{
    my ($boolean, $message) = @ARG;

    if( $boolean == false )
    {
        cluck "Warning: $message\n";
    }
}

sub Fatal
{
    my $message = $ARG[0] || null;
    
    confess "Exception: $message\n";
}

sub Warn
{
    my $message = $ARG[0] || null;
    
    cluck "Warning: $message\n";
}

sub Moan
{
    my $message = $ARG[0] || null;
    
    print STDERR "$message\n";
}

sub DeprecatedMethodWarning
{
    my $message = $ARG[0] || null;
    cluck "Deprecated method: $message\n";
}

sub WrongNumArgsError ()
{
    confess "Error: Wrong number of arguments to method\n";
}

true;
