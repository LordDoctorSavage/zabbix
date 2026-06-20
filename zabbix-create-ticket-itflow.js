try {
    // Get Webhook Media Type parameters 
    var params = JSON.parse(value);

	// Define Zabbix Event Tags - Needed for links + Automatic Closing
    var result = {
            tags: {}};
 
	// Define variables to assign proper ticket priority in ITFlow
	  var zabbixSeverity = params.zabbix_severity;
    var itflowPriority;
 
	// Map Zabbix severity to ITFlow priority
    if (zabbixSeverity === '5') {
        itflowPriority = 'High';
    }
    else if (zabbixSeverity === '4') {
        itflowPriority = 'Medium';
    }
    else {
        itflowPriority = 'Low';
    }

  // Define the JSON payload to send to ITFlow
	  var payload = {
        api_key:            params.api_key,
        ticket_subject:     params.ticket_subject,
        ticket_details:     params.ticket_details,
        ticket_priority:    itflowPriority,
        client_id:          params.client_id
    };	
    // HTTP POST via HttpRequest
    var req = new HttpRequest();
    req.addHeader('Content-Type: application/json');
    resp = req.post(params.URL, JSON.stringify(payload));

    // Check for errors with API posting, give a verbose reply.
    if (req.getStatus() !== 200) {
        throw 'Ticket creation failed, status ' + req.getStatus() + ': ' + resp;
    }

    // Add event tag with ITFlow ticket number

    resp = JSON.parse(resp);
    result.tags.itflow_ticket_number = resp.data[0].insert_id;

    return JSON.stringify(result);

}
catch (error) {
    // Error message in Zabbix log and abort with exception
    Zabbix.log(3, '[ itflow webhook ] Ticket creation failed: ' + error);
    throw 'Ticket creation failed: ' + error;
}
