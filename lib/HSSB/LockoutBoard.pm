package HSSB::LockoutBoard;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::Extensible;
use YAML ();
use List::Gen;
use String::Random qw(random_regex);

our $VERSION = '0.1';

our @possible_objectives = @{ YAML::LoadFile( 'data/objectives.yaml' ) };

get '/' => sub {
	my @boards = database->quick_select('boards', { state => [ "generated", "waiting", "playing" ] });
	my $username;
	if( defined logged_in_user ){
		$username = logged_in_user->{'username'};
	}
	foreach my $board ( @boards ){
		$board->{user_is_player} = database->quick_count(
			'teammembers',
			{
				board => $board->{board},
				player => $username,
			}
		);
	}
	template 'index' => {
		'title' => 'HSSB::LockoutBoard',
		boards => \@boards,
	};
};

get '/board/generate' => require_login sub {
	template 'generate' => {
		'title' => 'HSSB::LockoutBoard',
		user => logged_in_user,
		potential_players => [ database->quick_select('users', {}, { columns=>["username","id"]} )],
	};
};

post '/board/generate' => require_login sub {
	my $size = param 'size';
	send_error("Only sizes 9 and 25 are supported right now",400) unless grep { $size eq $_ } qw{9 25};

	my @team1_players = body_parameters->get_all('team-1');
	my @team2_players = body_parameters->get_all('team-2');

	send_error("Players are required!") unless @team1_players and @team2_players;

	my $board_id;
	my $retry_count = 50;
	do {
		$board_id = random_regex('[A-Za-z0-9]{32}');
		send_error "could not create a board" if $retry_count-- < 0;
	} until database->quick_insert('boards', { board => $board_id, state => \'"generated"', });

	my $stmt = database->prepare('insert into boardobjectives (board,objective,objective_index) values (?,?,?)');

	my $i = 0;
	foreach my $objective (List::Gen::makegen(@possible_objectives)->pick($size)){
		$stmt->execute($board_id, $objective->{objective}, $i++);
	}

	foreach my $player (@team1_players){
		database->quick_insert('teammembers', { board => $board_id, team => 1, player => $player });
	}
	foreach my $player (@team2_players){
		database->quick_insert('teammembers', { board => $board_id, team => 2, player => $player });
	}

	return redirect( "/board/$board_id" );
};

get '/board/:board' => require_login sub {
	my $board_id = param 'board';

	my @objectives = database->quick_select('scored_board', { board => $board_id }, { order_by => 'objective_index'});

	send_error("board not found", 404) unless scalar @objectives;

	my $team = database->quick_lookup('teammembers', { board => $board_id, player => logged_in_user->{'username'} }, 'team');

	my $our_score = grep { $_->{captured_by_team} == $team } @objectives;
	my $uncaptured_score = grep { !defined $_->{captured_by_team} } @objectives;
	my $their_score = (scalar @objectives) - $uncaptured_score - $our_score;

	template 'board' => {
		'title' => 'HSSB::LockoutBoard',
		objectives => \@objectives,
		board_id => $board_id,
		this_team => $team,
		scores => {
			ours => $our_score,
			theirs => $their_score,
			nobodys => $uncaptured_score,
		}
	};
};

get '/register' => sub {
	template 'register' => { title => "HSSB::LockoutBoard Sign-Up"};
};
post '/register' => sub {
	my $user = body_parameters->get('username');
	my $pass = body_parameters->get('password');
	my $rpwd = body_parameters->get('password-repeat');
	send_error "username required" unless $user;
	send_error "password required" unless $pass;
	send_error "repeated password doesn't match" unless $pass eq $rpwd;

	send_error "user already exists" if get_user_details $user;

	create_user username => $user;
	user_password username => $user, new_password => $pass;

	redirect '/';
};

get '/authtest' => require_login sub {
	use Data::Dumper;
	return Dumper( logged_in_user );
};

true;
