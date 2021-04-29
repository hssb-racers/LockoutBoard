#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


use HSSB::LockoutBoard;
use HSSB::LockoutBoard::API;

use Plack::Builder;

builder {
	mount '/'	=> HSSB::LockoutBoard->to_app;
	mount '/api'	=> HSSB::LockoutBoard::API->to_app;
}
