#! /usr/bin/perl
#######################################################################
# $Id: cvsnerftags.t,v 1.34 2010-12-21 06:19:44 dpchrist Exp $
#
# Regression test for cvsnerftags.
#
# Copyright 2010 by David Paul Christensen dpchrist@holgerdanske.com
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307,
# USA.
#######################################################################

use strict;
use warnings;

use Carp;
use Capture::Tiny		qw( tee );
use Config;
use Data::Dumper;
use Dpchrist::Term		qw( echo_system );
use File::Basename;
use File::Path			qw( make_path remove_tree );
use File::Spec::Functions	qw( :ALL );
use FindBin			qw( $Bin );

use Test::More tests => 18;

$| = 1;

my $ps1 = $0 . '$ ';

my $script	= abs2rel(
    catfile $Bin, '..', 'perl-bin', 'cvsnerftags'
);
my $dir		= abs2rel(
    catdir $Bin, '~tmp_' . basename(basename(__FILE__))
);
my $lib		= abs2rel(catdir $Bin, '..', 'lib');

my $line;
my $stdout;
my $stderr;
my $path_to_perl = $Config{perlpath};

sub gen_test_dir
{
    my $d = shift;
    confess "'$d' already exists"
	if -e $d;

    make_path $d, {verbose => 1};

    write_empty_testfile(catfile($d, 'empty'));
    write_binary_testfile(catfile($d, 'binary'));
    write_notags_testfile(catfile($d, 'notags'));
    write_tagged_testfile(catfile($d, "tagged"));
}

sub write_binary_testfile
{
    my $f = shift;
    print "$0 writing $f...";
    open my $fh, ">", "$f" or confess $!;
    binmode $fh or confess $!;
    my $s;
    $s .= chr $_ foreach (0..255);
    print $fh $s;
    close $fh or confess $!;
    print "done\n";
}

sub write_empty_testfile
{
    my $f = shift;
    print "$0 writing $f...";
    open my $fh, ">", "$f" or confess $!;
    close $fh or confess $!;
    print "done\n";
}

sub write_notags_testfile
{
    my $f = shift;
    print "$0 writing $f...";
    open my $fh, ">", "$f" or confess $!;
    print $fh "hello, world!\n" x 12;
    close $fh or confess $!;
    print "done\n";
}

sub write_tagged_testfile
{
    my $f = shift;
    print "$0 writing $f...";
    open my $fh, ">", "$f" or confess $!;
    print $fh join("\n",
'$Id: cvsnerftags.t,v 1.34 2010-12-21 06:19:44 dpchrist Exp $',
'our $VERSION = sprintf("%d.%03d", q$Revision: 1.34 $ =~ /(\d+)/g);',
'$Author: dpchrist $',
'$Date: 2010-12-21 06:19:44 $',
'$Header: /cvs/dpchrist/Dpchrist-CvsUtil/t/cvsnerftags.t,v 1.34 2010-12-21 06:19:44 dpchrist Exp $',
'$Name:  $',
'$Locker:  $',
# Log causes unending problems ...
'$RCSfile: cvsnerftags.t,v $',
'$Revision: 1.34 $',
'$Source: /cvs/dpchrist/Dpchrist-CvsUtil/t/cvsnerftags.t,v $',
    );
    close $fh or confess $!;
    print "done\n";
}

remove_tree $dir, {verbose => 1};

my $dir1 = $dir . __LINE__;

make_path $dir1, {verbose => 1};

confess "'$dir1' does not exist" unless -e $dir1;
$line = qq/$path_to_perl -I$lib "$script" "$dir1"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     1
    $stdout eq "\n\$ ${line}\n",
    'script should do nothing on an empty directory'
) or confess join(' ',
    Data::Dumper->Dump([$line, $stdout, $stderr],
		     [qw(line   stdout   stderr)]),
);

$line = qq/$path_to_perl -I$lib "$script" -v "$dir1"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     2
    $stdout =~ /skipping/,
    "--verbose should print message 'skipping'"
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

my $empty = catfile($dir1, 'empty');
write_empty_testfile($empty);
$line = qq/$path_to_perl -Ilib "$script" "$empty"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     3
    $stdout eq "\n\$ ${line}\n",
    'script should do nothing on an emtpy file'
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

$line = qq/$path_to_perl -I$lib "$script" -v "$empty"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     4
    $stdout eq "\n\$ ${line}\n",
    '--verbose should print nothing'
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

my $binary = catfile($dir1, 'binary');
write_binary_testfile($binary);

$line = qq/$path_to_perl -I$lib "$script" "$binary"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     5
    $stdout eq "\n\$ ${line}\n",
    'script should do nothing on a binary file'
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

$line = qq/$path_to_perl -I$lib "$script" -v "$binary"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     6
    $stdout =~ /skipping/,
    "--verbose should print 'skipping'"
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

my $notags = catfile($dir1, 'notags');
write_notags_testfile($notags);

$line = qq/$path_to_perl -I$lib "$script" "$notags"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     7
    $stdout eq "\n\$ ${line}\n",
    'script should do nothing on a text file without tags'
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

my $tagged = catfile($dir1, 'tagged');
my $tagged_orig = catfile($dir1, 'tagged-orig');
unlink $tagged_orig if -e $tagged_orig;
write_tagged_testfile($tagged);
$line = qq/$path_to_perl -I$lib "$script" --keep-orig -v "$tagged"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#     8
    $stdout =~ /_Author[^\n]+_/,
    'verify processing of Author tag'
) && ok(							#     9
    $stdout =~ /_Date[^\n]+_/,
    'confirm processing of Date tag'
) && ok(							#    10
    $stdout =~ /_Header[^\n]+_/,
    'confirm processing of Header tag'
) && ok(							#    11
    $stdout =~ /_Id[^\n]+_/,
    'confirm processing of Id tag'
) && ok(							#    12
    $stdout =~ /_Name[^\n]+_/,
    'confirm processing of Name tag'
) && ok(							#    13
    $stdout =~ /_Locker[^\n]+_/,
    'confirm processing of Locker tag'
) && ok(							#    14
    ### Log was getting changed every time I did a commit
    $stdout =~ /_RCSfile[^\n]+_/,
    'confirm processing of RCSfile tag'
) && ok(							#    15
    $stdout =~ /_Revision[^\n]+_/,
    'confirm processing of Revision tag'
) && ok(							#    16
    $stdout =~ /_Source[^\n]+_/,
    'confirm processing of Source tag'
) && ok(							#    17
    $stdout =~ /renaming[^\n]+\-orig/,
    'confirm --keep-orig option'
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

$line = qq/$path_to_perl -I$lib "$script" -v "$tagged-orig"/;
($stdout, $stderr) = tee {echo_system $line};
ok(								#    18
    $stdout =~ /skipping/,
    "script should skip '-orig' files"
) or confess join(' ',
    Data::Dumper->Dump([$stdout, $stderr],
		     [qw(stdout   stderr)]),
);

#######################################################################
