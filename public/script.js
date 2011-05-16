$(document).ready(function(){
        
        /* ************************************************************* INIT */
        var my_commands = []; // A log of all of the commands that I sent.
        var current_command_index; // Keeps track of where we are in my_commands.

        appendPromptString();

        if ( window.location.pathname == "/ssh" ) {
            // Inject a disconnect button in the header when connected.
            $("#header div h2").html('<button id="disconnect" class="button blue">Disconnect</button>');
            $("#disconnect").click(function() {
                    window.location = "/disconnect";
                });
        }

        $("#input").focus();

        /* *********************************************************** EVENTS */
        $("#input").keydown(function(e) {
                if ( e.keyCode == 13 && !e.shiftKey ) { // enter
                    sendCommand();
                } else {
                    resizeInput( $(this), false );
                }
            });
        $("#input").keyup(function(e) {
                resizeInput( $(this), false );
                
                rotateThroughSentCommands(e);
            });
        
        $("#send").click( sendCommand );

        /* ******************************************************** Functions */

        // 38 = up
        // 40 = down
        function rotateThroughSentCommands(e) {
            // Filter out keys.
            if ( !e.ctrlKey ) { return; }
            if ( e.keyCode != 38 && e.keyCode != 40) { return; }

            // Set the index to be one higher than the last command so we can adjust correctly in the up condition
            if ( current_command_index == undefined ) {
                current_command_index = my_commands.length;
            }

            // Rotate through the commands
            if ( e.keyCode == 38 ) { current_command_index -= 1; } // up
            if ( e.keyCode == 40 ) { current_command_index += 1; } // down

            // Continue looping through when out of range.
            if ( current_command_index > my_commands.length-1 ) {
                current_command_index = 0;
            } else if ( current_command_index < 0 ) {
                current_command_index = my_commands.length-1;
            }

            $("#input").val( my_commands[current_command_index] );
        }

        // @input = jquery object representing the input
        function resizeInput( input, clear ) {
            var lines = input.val().split("\n");

            // When enter is hit and the command is not sent, reset back to a one line field.
            if ( clear == true ) {
                input.val("");
                lines = [""];
            }

            var line_count = lines.length;

            for (var i in lines) {
                // 105 is the number of characters that I found fits in the textarea
                line_count += parseInt( lines[i].length / 105 );
            }

            line_count -= 1; // Compensate for the first line (27)
            if (line_count == 0) line_count = 1;
            var height = 27 + ((line_count)*15); // 15 is the height of an additional line.
                
            input.css("height", height);
        }
        
        function appendPromptString() {
            var host = "<span class='host_name'>"+$("#host_name").val()+"</span>",
                user = "<span class='user'>"+$("#user").val()+"</span>",
                pwd = "<span class='pwd'>"+$("#pwd").val()+"</span>";
            
            var conn_string = "["+user+"@"+host+":"+pwd+"]$ ";
            $("#screen").append("<p class='command'>"+conn_string+"</p>");
        }
        
        function sendCommand() {
            var command = $("#input").val();
            
            if ( command.trim().length > 0 ) {
                $("#screen p.command:last").append( command );
                ajax( "/command", { command: command }, function(data) {
                        my_commands.push( command );
                        current_command_index = undefined; // Reset so rotateThroughSentCommands works
                        resizeInput( $("#input"), true);

                        $("#pwd").val( data.pwd );
                        $("#screen").append("<p class='response'>"+data.result+"</p>");
                        appendPromptString();

                        // Scrolldown the window after appending text
                        var screen_object = $("#screen");
                        screen_object.attr( "scrollTop", screen_object.attr("scrollHeight") );
                    });
            } else {
                resizeInput( $("#input"), true);
            }

            $("#input").focus();
        }
        
        function displayErrorMessage(error) {
            console.log( "Error" );
            console.log( error );
            console.log( error.responseText );
        }

        function ajax(path, data, callback) {
            $.ajax({
                    url: path,
                        dataType: "json",
                        data: data,
                        type: "POST",
                        success: callback,
                        error: displayErrorMessage
                        });
        }
});
