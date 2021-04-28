package HSSB::LockoutBoard;
use Dancer2;
use YAML ();
use List::Gen;
use String::Random qw(random_regex);

our $VERSION = '0.1';

our @possible_objectives = @{ YAML::LoadFile( 'objectives.yaml' ) };


get '/' => sub {
	template 'index' => { 'title' => 'HSSB::LockoutBoard' };
};

get '/board/generate/:size' => sub {
	my $size = param 'size';
	send_error("Only sizes 9 and 25 are supported right now",400) unless grep { $size eq $_ } qw{9 25};

	my $board_id = random_regex('[A-Za-z0-9]{32}');

	my @objectives = List::Gen::makegen(@possible_objectives)->pick($size);

	mkdir "data/$board_id" or die "failed to create board state";

	YAML::DumpFile( "data/$board_id/objectives.yaml", @objectives );

	return redirect( "/board/$board_id" );
};

get '/board/:board' => sub {
	my $board_id = param 'board';
	send_error("board not found", 404) unless -f "data/$board_id/objectives.yaml";

	my @objectives = YAML::LoadFile( "data/$board_id/objectives.yaml" );

	template 'board' => {
		'title' => 'HSSB::LockoutBoard',
		objectives => \@objectives,
	};
};

true;
