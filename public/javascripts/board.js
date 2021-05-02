function CaptureQuest(){
	var quest = $(this)
	var board_id = $('#board').data('boardid');
	var quest_id = quest.attr('id').replace('quest-','');

	console.log("board id: "+ board_id);
	console.log("quest id: "+ quest_id);

	$.ajax({
		url: `/api/capture/${board_id}/${quest_id}`,
		dataType: "json",
		cache: false,
	}).done(function(){
		RefreshQuests(true);
	}).always(function(data,state){
		console.log("data:",data);
		console.log("state:",state);
	});
}

var constantReloader;
function RefreshQuests(singleRun = false){
	var board = $('#board');
	var board_id = board.data('boardid');

	$.ajax({
		url: `/api/board/${board_id}`,
		dataType: "json",
		cache: false,
	}).done(function(data){
		for( const obj of data.objectives ){
			var ID = obj.objective_index;
			$(`#quest-${ID}`).attr('data-captured',obj.capture_state)
		}

		board.data('state', data.board_state);

		board.find('.scores .our-score').text( data.scores.ours );
		board.find('.scores .their-score').text( data.scores.theirs );
		board.find('.scores .uncaptured').text( data.scores.nobodys );

		if( ['won','draw','lost'].includes(data.board_state) ){
			clearInterval(constantReloader);
		}

	});

}

$(document).ready(function(){
	$('body')
		.on('click', '#board .quest', CaptureQuest)
	;

	constantReloader = setInterval( RefreshQuests, 1100 );
});

