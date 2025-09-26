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

use strict;
#==============================================================================
# MODULE: FileIoHelper
#=====================
# DESCRIPTION:
#

#_ Module declaration

package FileIoHelper;

#_ Include libraries

use English;
use StdDefs;
use FileHandle;
use DirHandle;
use English;
use Carp;
use Assert;

#_ Export

use Exporter;
use base ('Exporter');
use vars qw(@EXPORT @EXPORT_OK);

@EXPORT = qw(
        CloseFiles
        GetStdError
        GetStdIn
        GetStdOut
        OpenFilesForAppending
        OpenFilesForReading
        OpenFilesForWriting
        );


@EXPORT_OK = qw(
        CloseFiles
        ColsFromFile
        ColsFromStream
        DirExists
        FileExists
        FileIsBinary
        FileIsEmpty
        FileEmptyOrAbsent
        FileNotEmpty
        GetDirContents
        GetStdError
        GetStdIn
        GetStdOut
        GetTempFileName
        GetFileBasename
        GetFilePath
        GetFileSuffix
        LinesFromFile
        OpenFilesForAppending
        OpenFilesForReading
        OpenFilesForWriting
        SplitPathName
        println
    );



#_ Module variables

my $tempFileNumber = 0;
my $tempFilePrefix = 'tmp';
my $tempFileSuffix = '.tmp';

#_ Module init

my $fhStdIn  = bless \*STDIN,  'FileHandle';
my $fhStdOut = bless \*STDOUT, 'FileHandle';
my $fhStdErr = bless \*STDERR, 'FileHandle';

#_ Public functions

sub CloseFiles
{
    foreach my $fhToClose (@ARG)
    {
        $fhToClose->close()
                or confess "Exception: Error closing file: $ERRNO\n";
    }
    return;
}

sub ColsFromFile($$)
{
    my($fileName, $aWantedCols) = @ARG;

    return ColsFromStream(OpenFilesForReading($fileName), $aWantedCols);
}

sub ColsFromStream($$)
{
    my($ist, $aWantedCols) = @ARG;
    my @aLists = ();

    while(my $line = $ist->getline)
    {
        if($line =~ m/\S/)
        {
            my @aCols = split(m/\s+/, $line);
            for(my $i=0; $i<@$aWantedCols; $i++)
            {
                push @{$aLists[$i]}, $aCols[$aWantedCols->[$i]];
            }
        }
    }
    return wantarray ? @aLists : $aLists[0];
}

sub DirExists($)    {-d $ARG[0]}
sub FileExists($)   {-e $ARG[0]}
sub FileIsBinary($) {-B $ARG[0]}
sub FileIsEmpty($)  {-z $ARG[0]}

sub FileNotEmpty($)
{
    my($file) = @ARG;
    return -e $file && !-z $file;
}

sub FileEmptyOrAbsent($)
{
    return !FileNotEmpty($ARG[0]);
}

sub GetStdIn()      {$fhStdIn}
sub GetStdOut()     {$fhStdOut}
sub GetStdError()   {$fhStdErr}

sub GetDirContents
{
    my($dirName, %hArgs) = @ARG;

    Assert::CheckArgHash(\%hArgs,
            'optional'=>[qw(incpath nodots)]
            );

    my $aFiles = [];
    my $aDirs = [];

    my $dir = new DirHandle($dirName);
    unless ($dir)
    {
        Fatal("Exception: cannot open directory $dirName: $ERRNO\n");
    }

    while(my $fileName = $dir->read)
    {
        if ($hArgs{'nodots'})
        {
            next if $fileName eq "." or $fileName eq "..";
        }
        my $pathName = "$dirName/$fileName";
        my $name = $hArgs{'incpath'} ? $pathName
                                       : $fileName;
        if(-d $pathName)
        {
            push @$aDirs, $name;
        }
        else
        {
            push @$aFiles, $name;
        }
    }
    $dir->close;
    return {'files' => $aFiles, 'dirs' => $aDirs};
}

sub GetTempFileName()
{
    my $fileName = $tempFilePrefix."_".$PROCESS_ID."_".($tempFileNumber++).$tempFileSuffix;
    Assert( !FileExists($fileName),"Temporary file $fileName already exists");
    return $fileName;
}

sub LinesFromFile($)
{
    my $file = shift;
    my $ist = OpenFilesForReading($file);
    my $array = [];
    while (my $line = $ist->getline)
    {
        chomp $line;
        push @$array, $line;
    }
    return $array;
}


sub OpenFilesForReading
{
    0 < @ARG or WrongNumArgsError();

    my @aHandles = ();
    my $fh;
    my $filename;

    for $filename (@ARG)
    {
        $fh = new FileHandle($filename, "r")
            or confess "Exception: Could not open $filename for reading: $ERRNO\n";
        push @aHandles, $fh;
    }

    return wantarray? @aHandles : $aHandles[0];
}

sub OpenFilesForAppending
{
    0 < @ARG or WrongNumArgsError();

    my @aFh = ();
    for my $file (@ARG)
    {
        my $fh = new FileHandle($file, "a")
            or confess "Exception: Could not open $file for reading: "
            .$ERRNO."\n";
        push @aFh, $fh;
    }
    return wantarray ? @aFh : $aFh[0];
}

sub OpenFilesForWriting
{
    0 < @ARG or WrongNumArgsError();

    my @aHandles = ();
    my $fh;
    my $filename;

    for $filename (@ARG)
    {
        $fh = new FileHandle($filename, "w")
            or confess "Exception: Could not open $filename for writing: $ERRNO\n";
        push @aHandles, $fh;
    }

    return wantarray? @aHandles : $aHandles[0];
}

sub SplitPathName($)
{
    my $pathname = shift;

    $pathname =~ m/(.*?)([^\/]+)$/;
    my $path = $1 || "./";
    my $basename = $2;

    my $suffix = $basename =~ s/\.([^\.]*)$// # if has extension
                ? $1                    # assign ext
                : null;                 # otherwise ext = null

    return $basename, $path, $suffix;
}

sub GetFileSuffix($)
{
    return (SplitPathName(shift))[2];
}

sub GetFileBasename($)
{
    return (SplitPathName(shift))[0];
}

sub GetFilePath($)
{
    return (SplitPathName(shift))[1];
}

sub println
{
    if (ref $ARG[0])
    {
        my $ost = shift;
        $ost->print(@ARG, "\n");
    }
    else
    {
        print @ARG, "\n";
    }
}


#====
# END
#==============================================================================
true;

__END__

=head1 Module

FileIoHelper

=head1 Description

Miscellaneous functions for files.

=head1 Functions

=over

=item CloseFiles

 Function:
   Closes all fhs given as arguments
 WARNING:
   CRE if there is an error on closing any stream
 ARGUMENTS:
   <@> array of streams
 RETURN:
   void

=item ColsFromFile

 Function: convenience function
   Returns arrays representing the specified columns from a file
 ARGUMENTS:
   1. <string> filename
   2. <\@ int> list of column numbers (starting 0..)
 RETURN:
   if scalar
       1. <\@ string> first column specified
   elsif array
       <@@ string> array of arrays of specified columns

=item ColsFromStream

 Function:
   Returns arrays representing the specified columns from a file
 ARGUMENTS:
   1. <ist> stream
   2. <\@ int> list of column numbers (starting 0..)
 RETURN:
   if scalar
       1. <\@ string> first column specified
   elsif array
       <@@ string> array of arrays of specified columns

=item FileExists

 Function: wrapper
   Returns whether file exists. Readable wrapper for "-e $filename"
 ARGUMENTS:
   1. <string> filename
 RETURN:
   <boolean> true iff file exists

=item GetStdError

 Function: accessor
   Returns stream version of STDERR
 RETURN:
   1. <ost> standard error stream
 SEE ALSO:

=item GetStdIn

 Function: accessor
   Returns stream version of STDIN
 RETURN:
   1. <ist> standard input stream

=item GetStdOut

 Function: accessor
   Returns stream version of STDOUT
 RETURN:
   1. <ost> standard output stream

=item GetTempFileName

 Function:
   Returns unique filename suitable for a temporary file. The name includes
       the process id number of the program and a count.
 RETURN:
   1. <string> filename

=item OpenFilesForAppending

 Function:
   Safely opens files for appending, returning ost objects
 WARNING:
   CRE if cannot open file
 ARGUMENTS:
   <@ strings> array of filenames
 RETURN:
   <@ ost> array of streams

=item OpenFilesForReading

 Function:
   Safely opens files for reading, returning ist objects
 WARNING:
   CRE if cannot open file
 ARGUMENTS:
   <@ strings> array of filenames
 RETURN:
   <@ ist> array of streams

=item OpenFilesForWriting

 Function:
   Safely opens files for writing, returning ost objects
 WARNING:
   CRE if cannot open file
 ARGUMENTS:
   <@ strings> array of filenames
 RETURN:
   <@ ost> array of streams

=item SplitPathName

 Function:
   Splits a pathname into the basename, path and suffix. Eg,
   for "/home/bsm/bilbo/flange.txt" :
       basename:   "flange"
       path:       "/home/bsm/bilbo/"
       suffix:     "txt"
   Does the job File::Basename::fileparse is meant to do.
 WARNING:
   May not work properly for "/public/fred/.." type names.
 ARGUMENTS:
   1. <string> filename
 RETURN:
   1. <string> basename
   2. <string> path
   3. <string> suffix

=item println

 Function:
   Same as CORE::print but automatically adds on an endline character.
 ARGUMENTS:
   <@ ?> things to print
 RETURN:
   void
