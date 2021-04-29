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
		board_id => $board_id,
	};
};

true;
