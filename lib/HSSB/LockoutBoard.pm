package HSSB::LockoutBoard;
use Dancer2;
use Dancer2::Plugin::Database;
use YAML ();
use List::Gen;
use String::Random qw(random_regex);

our $VERSION = '0.1';

our @possible_objectives = @{ YAML::LoadFile( 'data/objectives.yaml' ) };

get '/' => sub {
	template 'index' => { 'title' => 'HSSB::LockoutBoard' };
};

get '/board/generate/:size' => sub {
	my $size = param 'size';
	send_error("Only sizes 9 and 25 are supported right now",400) unless grep { $size eq $_ } qw{9 25};

	# TODO: check for ID collisions
	my $board_id = random_regex('[A-Za-z0-9]{32}');

	my $stmt = database->prepare('insert into boardobjectives (board,objective,objective_index) values (?,?,?)');

	my $i = 0;
	foreach my $objective (List::Gen::makegen(@possible_objectives)->pick($size)){
		$stmt->execute($board_id, $objective->{objective}, $i++);
	}

	return redirect( "/board/$board_id" );
};

get '/board/:board' => sub {
	my $board_id = param 'board';

	my @objectives = database->quick_select('boardobjectives', { board => $board_id }, { order_by => 'objective_index'});

	send_error("board not found", 404) unless scalar @objectives;

	template 'board' => {
		'title' => 'HSSB::LockoutBoard',
		objectives => \@objectives,
	};
};

get '/capture/:board/:objID/:player' => sub {
	my $board_id = param 'board';
	my $objID = param 'objID';
	my $player = param 'player';

	my $count = database->quick_count('boardobjectives', { board => $board_id, objective_index => int($objID) });
	error "found $count rows in table";
	send_error("board or objective not found", 400) unless $count == 1;

	my $result = database->quick_update('boardobjectives',
		{ board => $board_id, objective_index => $objID, captured_by => undef },
		{ captured_by => $player, capture_utctime => \'datetime("now")'}
	);

	if( defined $result ){
		return "OK" if $result == 1;
		return "NOK";
	}
	send_error "something went wrong in the DB";
};

true;
