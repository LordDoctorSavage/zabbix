try {
    // Get Webhook Media Type parameters 
    var params = JSON.parse(value);
	
	  var result = {
        tags: {}};

    // Define the JSON payload to send to ITFlow
    var payload = {
        api_key:            params.api_key,
        client_id:          params.client_id, 
		    ticket_id:          params.ticket_id
    };
	  payload = JSON.stringify(payload);

    // HTTP POST via HttpRequest
    var req = new HttpRequest();
    req.addHeader('Content-Type: application/json');
    resp = req.post(params.resolveURL, payload);

    // Check for errors with API posting, give a verbose reply.
    if (req.getStatus() !== 200) {
        throw 'Ticket close failed, status ' + req.getStatus() + ': ' + resp;
    }

    return 0;
	
	
}
catch (error) {
    // Error message in Zabbix log and abort with exception
    Zabbix.log(3, '[ itflow webhook ] Ticket close failed: ' + error);
    throw 'Ticket close failed: ' + error;
}
