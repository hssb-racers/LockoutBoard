package HSSB::LockoutBoard::API;
use Dancer2;
use Dancer2::Plugin::Database;
set serializer => 'JSON';

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
		return {state=>"OK"} if $result == 1;
		return {state=>"not OK"};
	}
	send_error "something went wrong in the DB";
};

true;
