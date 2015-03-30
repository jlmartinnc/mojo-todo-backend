#!/usr/bin/env perl
use ExtUtils::MakeMaker;

WriteMakefile(
	PREREQ_PM => {'Mojolicious' => '6.05', 'File::Slurp', 'Data::UUID', 'Data::GUID', 'local::lib'}
);
